#if KAMGAM_VISUAL_SCRIPTING
using System.Collections.Generic;
using Unity.VisualScripting;

using UnityEngine.UIElements;

namespace Kamgam.UIToolkitVisualScripting.Nodes
{
    public abstract class QueryManyBase<T> : Unit where T : class
    {
        [DoNotSerialize]
        public ValueInput source;

        [DoNotSerialize]
        public ValueInput queryName;

        [DoNotSerialize]
        public ValueInput queryClass;

        [DoNotSerialize]
        public ValueInput queryType;

        /// <summary>
        /// Disable if you want the query to be executed every time.
        /// </summary>
        [Serialize]
        [Inspectable]
        [InspectorExpandTooltip]
        public bool cacheResult { get; set; } = true;

        protected bool _cacheIsValid;
        protected List<VisualElement> _cachedResult = new List<VisualElement>();

        [DoNotSerialize]
        public ControlInput clearCacheTrigger;

        [DoNotSerialize]
        public ControlOutput cleared;

        [DoNotSerialize]
        public ValueOutput result { get; private set; }

        protected abstract string getSourceName();
        protected abstract T getQueryRoot(Flow flow, ValueInput input);
        protected abstract List<VisualElement> executeQuery(T queryRoot, UIElementType type, string name, string className);

        protected override void Definition()
        {
            _cacheIsValid = false;

            source = ValueInput<T>(getSourceName(), null);
            queryName = ValueInput<string>("Name", null);
            queryClass = ValueInput<string>("Class", null);
            queryType = ValueInput("Type", UIElementType.VisualElement);

            result = ValueOutput<List<VisualElement>>(nameof(result), (flow) => { return resolveQuery(flow); });

            cleared = ControlOutput(nameof(cleared));
            clearCacheTrigger = ControlInput(nameof(clearCacheTrigger), (flow) => { ClearCache(); return cleared; });

            Succession(clearCacheTrigger, cleared);
        }

        protected List<VisualElement> resolveQuery(Flow flow)
        {
            if (cacheResult && _cacheIsValid)
            {
                return _cachedResult;
            }

            var root = getQueryRoot(flow, source);
            if (root == null)
            {
                _cachedResult.Clear();
                _cacheIsValid = false;
                return _cachedResult;
            }

            var type = flow.GetValue<UIElementType>(queryType);
            var name = flow.GetValue<string>(queryName);
            var className = flow.GetValue<string>(queryClass);

            unregisterEvents(_cachedResult);
            _cachedResult = executeQuery(root, type, name, className);
            registerEvents(_cachedResult);

            _cacheIsValid = true;

            return _cachedResult;
        }

        protected void unregisterEvents(List<VisualElement> list)
        {
            if (list != null)
            {
                foreach (var ve in list)
                {
                    if (ve == null)
                        continue;

                    ve.UnregisterCallback<DetachFromPanelEvent>(onDetach);
                }
            }
        }

        protected void registerEvents(List<VisualElement> list)
        {
            if (list != null)
            {
                foreach (var ve in list)
                {
                    if (ve == null)
                        continue;

                    ve.RegisterCallback<DetachFromPanelEvent>(onDetach);
                }
            }
        }

        protected void onDetach(DetachFromPanelEvent evt)
        {
            ClearCache();
        }

        public virtual void ClearCache()
        {
            _cachedResult.Clear();
            _cacheIsValid = false;
        }
    }
}
#endif