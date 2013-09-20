using System;
using System.Diagnostics;
using System.Linq;
using System.Linq.Expressions;

namespace FlowControlExtensions
{
    public static class FlowControlExtensions
    {
        [DebuggerStepThrough]
        public static void DoIfHasValue<T>(this T? obj, Action<T> action, bool doContinue = true) where T : struct
        {
            if (obj.HasValue)
            {
                action(obj.Value);
            }
            if (doContinue)
                return;
            ThrowInvalidOperationException<T, T>();
        }

        [DebuggerStepThrough]
        public static TResult IfHasValue<T, TResult>(this T? obj, Func<T, TResult> func, bool doContinue = true, TResult defaultValue = default(TResult)) where T : struct
        {
            if (obj.HasValue)
            {
                return func(obj.Value);
            }
            return doContinue ? defaultValue : ThrowInvalidOperationException<T, TResult>();
        }

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
            throw new NullReferenceException(string.Format("Tried to reference an instance of {0}, but it was null", typeof(T).FullName));
        }

        [DebuggerStepThrough]
        private static TResult ThrowInvalidOperationException<T, TResult>()
        {
            throw new InvalidOperationException(string.Format("Tried to access value of nullable of {0}, but it had no value", typeof(T).FullName));
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