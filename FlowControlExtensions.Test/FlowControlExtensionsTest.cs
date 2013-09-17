using System;
using FluentAssertions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Example.Test
{
    [TestClass]
    public class FlowControlExtensionsTest
    {
        [TestMethod]
        public void Should_call_func_if_not_null()
        {
            var str = string.Empty;
            const string answer = "answer";
            str.IfNotNull(s => answer).Should().Be(answer);
        }

        [TestMethod]
        public void Should_throw_exception_if_null()
        {
            const string str = default(string);
            Action act = () => str.IfNotNull(s => (string)null, doContinue:false);
            act.ShouldThrow<NullReferenceException>();
        }

        [TestMethod]
        public void Should_return_default_for_type_if_null()
        {
            const string str = default(string);
            Assert.IsNull(str.IfNotNull(s => string.Empty));            
        }

        [TestMethod]
        public void Should_name_variable_and_class_and_method_in_exception()
        {
            SomeClass someObject = null;
            Action act = () => someObject.IfNotNull(strange => strange.SomeMethod(), false);
            act.ShouldThrow<NullReferenceException>()
                .Where(e => e.Message.Contains("SomeMethod(...)"))
                .Where(e => e.Message.Contains("strange"))
                .Where(e => e.Message.Contains("SomeClass"));
        }

        [TestMethod]
        public void Should_name_class_in_exception()
        {
            var someObject = new SomeClass();
            const string str = default(string);
            Action act = () => str.DoIfNotNull(strange => someObject.SomeProperty = strange, false);
            act.ShouldThrow<NullReferenceException>()
                .Where(e => e.Message.Contains("System.String"));
        }

        [TestMethod]
        public void Should_name_variable_and_class_and_property_in_exception()
        {
            Action act = () => ((SomeClass)null).IfNotNull(strange => strange.SomeProperty, false);
            act.ShouldThrow<NullReferenceException>()
                .Where(e => e.Message.Contains("SomeProperty"))
                .Where(e => e.Message.Contains("strange"))
                .Where(e => e.Message.Contains("SomeClass"));
        }

        [TestMethod]
        public void Should_return_default_when_null()
        {
            var res = ((SomeClass) null).IfNotNull(s => s.SomeProperty, defaultValue: string.Empty);
            res.Should().BeEmpty();
        }
        
        private class SomeClass
        {
            public string SomeProperty { get; set; }

            public string SomeMethod()
            {
                return "SomeMethod-result";
            }
        }
    }
}
