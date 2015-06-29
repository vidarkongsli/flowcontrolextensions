using System;
using FluentAssertions;
using NUnit.Framework;
using Assert = NUnit.Framework.Assert;

namespace FlowControlExtensions.Test
{
    [TestFixture]
    public class FlowControlExtensions_DoIfHasValue
    {
        [Test]
        public void Should_call_action_when_nullable_has_value()
        {
            var wasCalled = false;
            (new int?(1)).DoIfHasValue(x => wasCalled = true);
            wasCalled.Should().Be(true);
        }

        [Test]
        public void Should_continue_executing_when_nullable_has_no_value()
        {
            (new int?()).DoIfHasValue(x => Assert.Fail("Called action even if object was null."));
        }

        [Test]
        public void Should_throw_exception_when_nullable_has_no_value_and_do_not_continue()
        {
            Action act = () => (new int?()).DoIfHasValue(x => Assert.Fail("Called action even if object was null."), doContinue: false);
            act.ShouldThrow<InvalidOperationException>();
        }
    }
}
