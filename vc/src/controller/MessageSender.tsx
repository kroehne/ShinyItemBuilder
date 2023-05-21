/**
 * Send a message to the TaskPlayer running in the given target window.
 * 
 * This method covers all messages defined by the TaskPlayer API
 * (even though we currently do not use all of them).
 */
export function sendMessageToTaskPlayer(targetWindow : MessageEventSource, payload : 
    // configuration control
    { eventType: 'setWaitMessages', primary: string, secondary: string} | 
    { eventType: 'addItem', itemConfig: object, resourcePath: string, externalResourcePath: string, libraryPathsMap: {MathJax: string} } |
    { eventType: 'clearItems'} |
    { eventType: 'setPreload', itemName: string} |
    // trace control
    { eventType: 'insertMessageInTrace', message: string} |
    { eventType: 'logStateToTrace'} |
    { eventType: 'flushTrace'} |
    { eventType: 'setTraceLogTransmissionChannel', channel: 'postMessage', targetWindowType?: string, targetOrigin?: string, interval: number} |
    { eventType: 'setTraceLogTransmissionChannel', channel: 'http',  transmitUrl?: string,  interval: number,  httpTimeout?: number} |
    { eventType: 'setTraceLogTransmissionChannel', channel: 'console',  interval: number} |
    { eventType: 'setTraceContextId', contextId: string} |
    // recordings control 
    { eventType: 'setRecordingTransmissionChannel', channel: 'http', transmitUrl: string, httpTimeout: number} |
    { eventType: 'setRecordingTransmissionChannel', channel: 'console'} |
    { eventType: 'setRecordingContextId', contextId: string} |
    // user control
    { eventType: 'setUserId', id: string} |
    { eventType: 'logout'} |
    { eventType: 'getUserId'} |
    { eventType: 'showLogin', titleLabel: string, fieldLabel: string, buttonLabel: string} |
    // task control
    { eventType: 'startTask', scope: string, item: string, task: string} |
    { eventType: 'stopTask'} |
    { eventType: 'pauseTask' } |
    { eventType: 'resumeTask' } |
    { eventType: 'getTask' } |
    { eventType: 'setTaskSequencer', targetWindowType: 'parent', targetOrigin: string} |
    { eventType: 'setSwitchAvailability', request: 'nextTask' | 'previousTask' | 'cancelTask', value: boolean} |
    { eventType: 'setSwitchAvailability', request: 'goToTask', scope: string, item?: string, task: string, value: boolean} |
    // task state control
    { eventType: 'getTasksState'} |
    { eventType: 'clearTasksState' } |
    { eventType: 'preloadTasksState', state: string } |
    // scoring control
    { eventType: 'getScoringResult'} |
    // state machine control
    { eventType: 'sendStatemachineEvent', event: string} |
    // header control
    { eventType: 'setHeaderButtons', headerButtons: HeaderButtonDescription[]} |
    { eventType: 'setMenuCarousels', course: string[], scopes: HeaderMenuScopeDescription[]} |
    // developer mode control
    { eventType: 'activateDebuggingWindows', scoreHotKey: string, traceHotKey: string, statemachineHotKey: string} 
  ) 
{
  targetWindow.postMessage(JSON.stringify(payload), { targetOrigin: '*'});
}


export interface HeaderButtonDescription {
  image?: string, 
  text: string,
  event: string,
  height: number,
  width: number
}

export interface HeaderMenuScopeDescription {
  name: string, 
  tasks: {item: string, task: string}[]
}