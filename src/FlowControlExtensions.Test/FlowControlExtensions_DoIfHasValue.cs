using System;
using FluentAssertions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace FlowControlExtensions.Test
{
    [TestClass]
    public class FlowControlExtensions_DoIfHasValue
    {
        [TestMethod]
        public void Should_call_action_when_nullable_has_value()
        {
            var wasCalled = false;
            (new int?(1)).DoIfHasValue(x => wasCalled = true);
            wasCalled.Should().Be(true);
        }

        [TestMethod]
        public void Should_continue_executing_when_nullable_has_no_value()
        {
            (new int?()).DoIfHasValue(x => Assert.Fail("Called action even if object was null."));
        }

        [TestMethod]
        public void Should_throw_exception_when_nullable_has_no_value_and_do_not_continue()
        {
            Action act = () => (new int?()).DoIfHasValue(x => Assert.Fail("Called action even if object was null."), doContinue: false);
            act.ShouldThrow<InvalidOperationException>();
        }
    }
}
