properties {
    $base_directory = Resolve-Path .
    $src_directory = "$base_directory\src"
    $output_directory = "$base_directory\build"
    $dist_directory = "$base_directory\dist"
    $sln_file = "$src_directory\GoWithTheFlow.sln"
    $target_config = "release"
    $framework_version = "v4.5.2"
    $packages_dir = "$src_directory\packages"
    $buildNumber = 0;
    $version = "1.0.0.0"
    $preRelease = $null
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

task -name patch-assemblyinfo -action {
    exec {
        function PatchFile ([string] $pattern, [string] $replaceString, [string] $fullPath){
            (gc $fullPath) -replace $pattern, $replaceString | out-file $fullPath
        }
    
        Get-ChildItem $src_dir -Recurse | ? { $_.Name -eq "AssemblyInfo.cs" } | % {
            $assemblyVersionPattern = 'AssemblyVersion\("(\d+).(\d+).(\*|\d+\.\d+|\d+\.\*)"\)' 
            $assembyVersionReplacement ='AssemblyVersion("' + $version + '")'
            PatchFile $assemblyVersionPattern $assembyVersionReplacement $_.FullName
    
            $assemblyFileVersionPattern = 'AssemblyFileVersion\("(\d+).(\d+).(\*|\d+\.\d+|\d+\.\*)"\)' 
            $assembyFileVersionReplacement ='AssemblyFileVersion("' + $version + '")'
            PatchFile $assemblyFileVersionPattern $assembyFileVersionReplacement $_.FullName
        }    
    }
}

task Compile-release -depends clean, patch-assemblyinfo, restore-nuget, Compile -action {
    exec {
        git checkout -- "$src_directory/FlowControlExtensions.Test/Properties/AssemblyInfo.cs"
        git checkout -- "$src_directory/FlowControlExtensions/Properties/AssemblyInfo.cs"
    }
} 

task Compile -depends restore-nuget {
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

task copy-to-dist -depends Compile-release, runtests -action {
    exec {
        md $dist_directory\lib\net40 -ErrorAction 'SilentlyContinue' | out-null
        md $dist_directory\lib\net45 -ErrorAction 'SilentlyContinue' | out-null
        copy "$src_directory\FlowControlExtensions\bin\$target_config\GoWithTheFlow.dll" $dist_directory\lib\net40
        copy "$src_directory\FlowControlExtensions\bin\$target_config\GoWithTheFlow.dll" $dist_directory\lib\net45
    }
}

task CreateNuGetPackage -depends copy-to-dist {
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

    copy-item $src_directory\Flowcontrolextensions\GoWithTheFlow.nuspec $dist_directory
    exec { nuget pack $dist_directory\GoWithTheFlow.nuspec -BasePath $dist_directory -o $dist_directory -version $packageVersion }
}

function nunit_console_runner {
    $nunit_dir = gci -Path "$src_dir\packages" -Filter Nunit.Runners* | sort -Property Name | select -Last 1
    gci -Path $nunit_dir.fullname -Filter nunit-console.exe -Recurse | select -First 1 -ExpandProperty FullName
}

function run-msbuild($sln_file, $t, $cfg) {
    msbuild /nologo /verbosity:q $sln_file /t:$t /p:Configuration=$cfg /p:TargetFrameworkVersion=v4.5
}

function run_tests($testassemblies, $reportfile, $suiteName) {
    if (-not(test-path $test_report_dir)) { md $test_report_dir | out-null }
    & (nunit_console_runner) $testassemblies /nologo /nodots /framework:v4.5 /xml=$reportfile 
}