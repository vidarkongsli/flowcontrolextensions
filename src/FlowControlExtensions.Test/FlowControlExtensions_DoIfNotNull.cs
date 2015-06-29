using System;
using FluentAssertions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlowControlExtensions.Test
{
    [TestClass]
    public class FlowControlExtensions_DoIfNotNull
    {
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
        public void Should_call_action_when_not_null()
        {
            var wasCalled = false;
            string.Empty.DoIfNotNull(x => wasCalled = true);
            wasCalled.Should().Be(true);
        }

        [TestMethod]
        public void Should_continue_executing_when_null()
        {
            ((string)null).DoIfNotNull(x => Assert.Fail("Called action even if object was null."));
        }

        [TestMethod]
        public void Should_throw_exception_when_null_and_do_not_continue()
        {
            Action act = () => ((string)null).DoIfNotNull(x => Assert.Fail("Called action even if object was null."), doContinue: false);
            act.ShouldThrow<NullReferenceException>();
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
