using System;
using System.Diagnostics;
using System.Linq;
using System.Linq.Expressions;

namespace Example
{
    public static class FlowControlExtensions
    {
        [DebuggerStepThrough]
        public static TResult IfNotNull<T,TResult>(this T obj, Expression<Func<T, TResult>> func, bool doContinue = true, TResult defaultValue = default(TResult)) where T : class
        {
            if (obj != null)
            {
                return func.Compile()(obj);
            }
            if (doContinue) return defaultValue;
            var parameterName = func.Parameters.First().Name;
            var parameterType = typeof (T).FullName;
            var visitor = new MemberNameCollector(parameterName);
            visitor.Visit(func.Body);
            throw new NullReferenceException(string.Format("Tried to reference .{0} on parameter with name '{1}' of type {2}, but it was null",
                visitor.MemberName, parameterName, parameterType));
        }

        [DebuggerStepThrough]
        public static void DoIfNotNull<T>(this T obj, Action<T> action, bool doContinue = true) where T : class
        {
            if (obj != null)
            {
                action(obj);
            }
            if (doContinue) return;
            throw new NullReferenceException(string.Format("Reference with type {0} was null.", typeof (T).FullName));
        }

        private class MemberNameCollector : ExpressionVisitor
        {
            public string MemberName = "Unknown";
            private readonly string _parameterName;

            public MemberNameCollector(string parameterName)
            {
                _parameterName = parameterName;
            }

            protected override Expression VisitMethodCall(MethodCallExpression node)
            {
                if (node.Object != null && node.Object.NodeType == ExpressionType.Parameter && _parameterName == node.Object.ToString())
                {
                    MemberName = node.Method.Name + "(...)";
                }
                return base.VisitMethodCall(node);
            }

            protected override Expression VisitMember(MemberExpression node)
            {
                if (node.NodeType == ExpressionType.MemberAccess && node.Expression.ToString() == _parameterName)
                {
                    MemberName = node.Member.Name;
                }
                return base.VisitMember(node);
            }
        }
    }
}