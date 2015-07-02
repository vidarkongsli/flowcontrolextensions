Go with the flow
=====================
Contains simple library for managing flow control for null checks in C#.
See blog post [Handling null checks efficiently](http://www.kongsli.net/nblog/2013/09/17/handling-null-checks-efficiently/)

Installation
------------

	PM> Install-Package GoWithTheFlow -Pre

Usage summary
-------------

|Code snippet | Description |
|--- | --- |
|`person.Address.DoIfNotNull(a => a.WriteToConsole());`|	Runs a statement. Continue execution in case of null.|
|`person.Address.DoIfNotNull(a => a.WriteToConsole(), doContinue : false);`|	Runs a statement. Throws a NullReferenceException in case of null. Somewhat improved exception message compared to OOTB.|
|`person.Address.IfNotNull(a => a.ToString());`|	Evaluates an expression. Returns default(T) in case of null.|
|`person.Address.IfNotNull(a => a.ToString(), defaultValue : "(unknown)");`|	Evaluates an expression. Returns "(unknown)" in case of null.|
|`person.Address.IfNotNull(a => a.ToString(), doContinue: false);`|	Evaluates an expression. Throws a NullReferenceException in case of null. Improved exception message compared to OOTB.|

