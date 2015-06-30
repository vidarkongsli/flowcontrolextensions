properties {
    $base_directory = Resolve-Path .
    $src_directory = "$base_directory\src"
    $output_directory = "$base_directory\build"
    $dist_directory = "$base_directory\dist"
    $sln_file = "$src_directory\GoWithTheFlow.sln"
    $target_config = "debug"
    $framework_version = "v4.5.2"
    $xunit_path = "$src_directory\packages\xunit.runner.console.2.0.0\tools\xunit.console.exe"
    $ilmerge_path = "$src_directory\packages\ILMerge.2.14.1208\tools\ILMerge.exe"
    $nuget_path = "$src_directory\.nuget\nuget.exe"
    $packages_dir = "$src_directory\packages"
    $buildNumber = 0;
    $version = "1.5.0.0"
    $preRelease = $null
    $runsOnBuildServer = $false
    $test_report_dir = "$base_directory\TestResult"
}

task default -depends Clean, RunTests, CreateNuGetPackage
task appVeyor -depends Clean, CreateNuGetPackage

task -name restore-nuget -action {
    exec {
        nuget restore $sln_file
    }
}


task Clean {
    rmdir $output_directory -ea SilentlyContinue -recurse
    rmdir $dist_directory -ea SilentlyContinue -recurse
    exec { run-msbuild $sln_file 'clean' $target_config }
}

task -name patch-assemblyinfo -precondition { return $runsOnBuildServer } -action {
    exec {
        function PatchFile ([string] $pattern, [string] $replaceString, [string] $fullPath){
            (gc $fullPath) -replace $pattern, $replaceString | out-file $fullPath
        }
    
        Get-ChildItem $src_dir -Recurse | ? { $_.Name -eq "AssemblyInfo.cs" } | % {
            $assemblyVersionPattern = 'AssemblyVersion\("(\d+).(\d+).(\*|\d+\.\d+|\d+\.\*)"\)' 
            $assembyVersionReplacement ='AssemblyVersion("' + $build_version + '")'
            PatchFile $assemblyVersionPattern $assembyVersionReplacement $_.FullName
    
            $assemblyFileVersionPattern = 'AssemblyFileVersion\("(\d+).(\d+).(\*|\d+\.\d+|\d+\.\*)"\)' 
            $assembyFileVersionReplacement ='AssemblyFileVersion("' + $build_version + '")'
            PatchFile $assemblyFileVersionPattern $assembyFileVersionReplacement $_.FullName
        }    
    }
}

task Compile -depends restore-nuget, patch-assemblyinfo {
    exec { run-msbuild $sln_file 'build' $target_config }
}


task -name ensure-nunit -action {
    exec {
        if (-not(gci -Path $packages_dir -Filter Nunit.Runners*)) {
            nuget install Nunit.Runners -SolutionDirectory $src_directory     
        }
    }
}

task RunTests -depends Compile, ensure-nunit {
    exec {
        run_tests "$src_directory\FlowControlExtensions.Test\bin\$target_config\GoWithTheFlow.Test.dll" `
            "$test_report_dir\$($build_version)_unit_TestResult.xml" "Unit tests"
    }
}

task ILMerge -depends Compile {
    $input_dlls = "$output_directory\Thinktecture.IdentityServer3.dll"

    Get-ChildItem -Path $output_directory -Filter *.dll |
        foreach-object {
            # Exclude Thinktecture.IdentityServer3.dll as that will be the primary assembly
            if ("$_" -ne "Thinktecture.IdentityServer3.dll" -and
                "$_" -ne "Owin.dll") {
                $input_dlls = "$input_dlls $output_directory\$_"
            }
    }

    New-Item $dist_directory\lib\net45 -Type Directory
    Invoke-Expression "$ilmerge_path /targetplatform:v4 /internalize /allowDup /target:library /out:$dist_directory\lib\net45\Thinktecture.IdentityServer3.dll $input_dlls"
}

task CreateNuGetPackage -depends ILMerge {
    $vSplit = $version.Split('.')
    if($vSplit.Length -ne 4)
    {
        throw "Version number is invalid. Must be in the form of 0.0.0.0"
    }
    $major = $vSplit[0]
    $minor = $vSplit[1]
    $patch = $vSplit[2]
    $packageVersion =  "$major.$minor.$patch"
    if($preRelease){
        $packageVersion = "$packageVersion-$preRelease"
    }
    
    if ($buildNumber -ne 0){
        $packageVersion = $packageVersion + "-build" + $buildNumber.ToString().PadLeft(5,'0')
    }


    copy-item $src_directory\IdentityServer3.nuspec $dist_directory
    copy-item $output_directory\Thinktecture.IdentityServer3.xml $dist_directory\lib\net45\
    exec { . $nuget_path pack $dist_directory\IdentityServer3.nuspec -BasePath $dist_directory -o $dist_directory -version $packageVersion }
}



function nunit_console_runner {
    $nunit_dir = gci -Path "$src_dir\packages" -Filter Nunit.Runners* | sort -Property Name | select -Last 1
    gci -Path $nunit_dir.fullname -Filter nunit-console.exe -Recurse | select -First 1 -ExpandProperty FullName
}

function run-msbuild($sln_file, $t, $cfg) {
    $v = if ($runsOnBuildServer) { 'n'} else { 'q' } 
    msbuild /nologo /verbosity:$v $sln_file /t:$t /p:Configuration=$cfg /p:TargetFrameworkVersion=v4.5
}

function run_tests($testassemblies, $reportfile, $suiteName) {
    if ($runsOnBuildServer) { }
    if (-not(test-path $test_report_dir)) { md $test_report_dir | out-null }
    & (nunit_console_runner) $testassemblies /nologo /nodots /framework:v4.5 /xml=$reportfile 
    if ($runsOnBuildServer) { 
        
    }
}