import { v4 } from 'uuid'; 
import MessageReceiver, { TaskRequestDetails, RequestType, ShinySwitchRequest } from "./MessageReceiver";
import { sendMessageToTaskPlayer } from "./MessageSender";
import { 
  ControllerConfiguration, 
  LogTransmissionConfiguration, 
  AssessmentConfiguration, 
  downloadAssessmentConfig, 
  ScalingConfiguration,
  extractScalingConfigurationFromQuery,
  extractUserIdFromQuery,
  downloadItemConfig,
} from "../utils/FileDownload"; 
import TaskSequencer, { Decision } from "./TaskSequencer";
import { TaskIdentification } from "../utils/FileDownload";
import PlayerCatalog from '../runtime/PlayerCatalog';
import ItemCatalog from '../runtime/ItemCatalog';

/**
 * Controller coordinating actions required to run the tasks list in the available task players.
 * 
 * The controller supports multiple task player instances running in different frames (to support
 * multiple CBA runtime versions). It gets access to these instances and their frames via a player catalog. 
 * 
 * All activity is triggered by the events coming in from the CBA runtimes once the task players have started there:
 * 
 * The task-player-ready events coming in trigger configuration of the sending task player:
 *  - Set session ID (each player gets its own session ID).
 *  - Configure trace log transmission channel for the sending task player.
 * 
 * The last task-player-ready event coming in also triggers the login phase:
 *  - Show login dialog in the sending task player.
 * 
 * The login-done event triggers the initialization phase which ends with starting a first task:
 *  - Set the user ID for all available task players.
 *  - Download of configuration data and item data.
 *  - For each item not yet registered in the item catalog:
 *     * Register the item in the item catalog.
 *     * Determine the compatible task players and upload the item configuration there.
 *  - Establish a task sequencer.
 *  - Obtain the first task to run from the task sequencer and start it on the task player determined by the task sequencer. 
 * 
 * The task-switch-request events trigger task-switch responses determined by our task sequencer logic:
 *  - The controller informs the task sequencer about the request and the task player sending it. 
 *  - The task sequencer tells the controller what to do next: Show a login dialog or start a task on a specific task player. 
 *  - The controller stops the currently running task and 
 *     * either shows a login dialog on the chosen task player 
 *     * or starts the next task on the chosen task player.
 *  - If the task sequencer does not choose the next task player the controller picks one:
 *     * If the previous task player is compatible, it reuses that one. 
 *     * Otherwise It picks some compatible player. 
 * 
 * Since the controller does not maintain any internal memory (for now) 
 * it is just a method that configures the listeners in the message receiver.
 * 
 */


/**
 * Establish the controller, i.e. configure listeners in the message receiver. 
 * 
 * This defines our response to the messages coming in from the task players running in the CBA runtimes. 
 * 
 * The controller's activity is driven by the messages coming in from the task players: 
 * - The 'ready' messages trigger the login phase.
 * - The 'login-done' message triggers the item initialization phase which will download items and start the first task of the assessment.
 * - Task switch request messages trigger task selection and task stop/start respones. 
 */
export function configureMessageReceiver(
  messageReceiver: MessageReceiver, 
  taskSequencer: TaskSequencer, 
  playerCatalog: PlayerCatalog,
  itemCatalog: ItemCatalog,  
  controllerConfig: ControllerConfiguration
) 
{


  // What to do once a task switch request arrives: get next action from task sequencer and run it.
  messageReceiver.setTaskSwitchRequestListener((sendingWindow: MessageEventSource, request: RequestType, requestDetails?: TaskRequestDetails) => {
    
    const sendingPlayerId = playerCatalog.getPlayerId(sendingWindow);
    if (sendingPlayerId === undefined) {
      console.warn(`Received switch request from unknown task player frame. This is an internal error. We ignored the request.`);
      return;
    }
    
    const decision = getNextAction(sendingPlayerId, request, requestDetails, taskSequencer);
    switch (decision.type) {
      case 'blocked': 
        console.log(`Cannot follow switch request ${request}: ${decision.reason}. We ignored the request.`)
        /********* "Hack" to send PM to parent frame when the last task of the sequence has been reached to signal the end of the test *******/
        // if(request === "nextTask"){
        //     window.parent.postMessage(
        //       JSON.stringify({eventType: "endOfSequence"}),
        //       "*"
        //     );
        // }
        return;
      case 'login': 
        processLoginRequest(decision.playerId, sendingPlayerId, sendingWindow, playerCatalog);
        return;
      case 'taskSwitch': 
        //task switch determined by shiny app based on scoring result
          // processTaskSwitchRequest(decision.playerId, decision.nextTask, sendingPlayerId, sendingWindow, itemCatalog, playerCatalog);
          getScoringResult(sendingWindow);
        return;
      default: 
        const _exhaustiveCheck : never = decision;
        return _exhaustiveCheck;
    }

  })

  messageReceiver.setShinyTaskSwitchRequestListener((sendingWindow: MessageEventSource, requestDetails: ShinySwitchRequest) => {
    requestDetails.scope = requestDetails.scope ? requestDetails.scope : ["A"];
    processShinyTaskSwitchRequest({item: requestDetails.item[0], task: requestDetails.task[0], scope: requestDetails.scope[0]} as TaskIdentification, itemCatalog, playerCatalog);
  });

  // What to do once login is finished: Download configuration, set up everything, and start first task.
  messageReceiver.setLoginDialogClosedListener((sendingWindow, nickname) => {
    playerCatalog.doToAll((targetWindow: MessageEventSource) => setUserId(nickname, targetWindow));
    playerCatalog.doToAll((targetWindow: MessageEventSource) => setTaskSequencer(targetWindow));
    downloadAssessmentConfig()
      .then((configuration) => {
        if (configuration.tasks.length < 1) {
          throw new Error(`No tasks declared in assessment configuration ${configuration}`);
        }
        taskSequencer.initialize(configuration, playerCatalog);
        loadItemsAndStartFirstTask(configuration, controllerConfig.mathJaxCdnUrl, playerCatalog, itemCatalog, taskSequencer);
      })
      .catch((error) => {
        console.warn(`Could not initialize assessment properly: ${error.message}`);
      });
  })
  
  // What to do once the task player is ready: Load required items and show login dialog.
  messageReceiver.setPlayerReadyListener((sendingWindow) => {
    playerCatalog.receiveReadySignal(sendingWindow);
    
    // initializeSessionAndShowLogin(sendingWindow, controllerConfig.traceLogTransmission, playerCatalog)
    // setUserId("DEPP", sendingWindow);

    sendMessageToTaskPlayer(sendingWindow, {
      eventType: 'setTraceLogTransmissionChannel', 
      channel: 'postMessage', 
      interval: 5000, 
      targetOrigin: '*', 
      targetWindowType: "parent"
    });    
    sendMessageToTaskPlayer(sendingWindow, {eventType: 'setTraceContextId', contextId: buildTraceContextId()});
    playerCatalog.doToAll((targetWindow: MessageEventSource) => setUserId(extractUserIdFromQuery("session"), targetWindow));
    playerCatalog.doToAll((targetWindow: MessageEventSource) => setTaskSequencer(targetWindow));
    downloadAssessmentConfig()
    .then((configuration) => {
        if (configuration.tasks.length < 1) {
          throw new Error(`No tasks declared in assessment configuration ${configuration}`);
        }
        taskSequencer.initialize(configuration, playerCatalog);
        playerCatalog.doToAll((targetWindow: MessageEventSource) => setScalingConfiguration(targetWindow, extractScalingConfigurationFromQuery()));      
        loadItemsAndStartFirstTask(configuration, controllerConfig.mathJaxCdnUrl, playerCatalog, itemCatalog, taskSequencer);        
      })       
      .catch((error) => {
        console.warn(`Could not initialize assessment properly: ${error.message}`);
      });
  });

}

/**
 * Obtain the next action by asking the task sequencer. 
 */
 function getNextAction(
  sendingPlayerId: string, 
  request: RequestType, 
  requestDetails: TaskRequestDetails | undefined, 
  taskSequencer: TaskSequencer
  ) : Decision
{
  switch (request) {
    case 'cancelTask': return taskSequencer.cancel(sendingPlayerId);
    case 'nextTask': return taskSequencer.nextTask(sendingPlayerId);
    case 'previousTask': return taskSequencer.backTask(sendingPlayerId);
    case 'goToTask': {
      if (requestDetails === undefined) return { type: 'blocked', reason: 'Task specification is missing in goToTask request.' }
      return taskSequencer.goToTask(sendingPlayerId, requestDetails);
    }
    default: {
      const _exhaustiveCheck: never = request;
      return _exhaustiveCheck;
    }
  }
}

/**
 * Process a request to show a new login.
 * 
 * We stop the currently running task and show the login dialog.
 */
function processLoginRequest(advisedPlayerId: string | undefined, sendingPlayerId: string, sendingWindow: MessageEventSource, playerCatalog: PlayerCatalog) : void {
  const targetPlayer = getTargetPlayer(advisedPlayerId, sendingPlayerId, sendingWindow, playerCatalog);

  stopTask(sendingWindow);
  playerCatalog.doToAll((targetWindow: MessageEventSource) => {logout(targetWindow)});
  playerCatalog.show(targetPlayer.id);
  showLogin(targetPlayer.frameWindow);
  return;
}

/**
 * Process a request to switch to another task.
 * 
 * We stop the currently running task and start the new one.
 */
function processTaskSwitchRequest(
  advisedPlayerId: string | undefined, 
  nextTask: TaskIdentification, 
  sendingPlayerId: string, 
  sendingWindow: MessageEventSource, 
  itemCatalog: ItemCatalog, 
  playerCatalog: PlayerCatalog) : void 
{
  const targetItemVersion = itemCatalog.getVersion(nextTask.item);
  if (targetItemVersion === undefined) {
    console.warn(`Received task switch request to unknown item ${nextTask.item}. We ignored the request.`);
    return;
  }

  const compatiblePlayer = getCompatiblePlayer(advisedPlayerId, targetItemVersion, {id: sendingPlayerId, frameWindow: sendingWindow}, playerCatalog);
  if (compatiblePlayer === undefined) {
    console.warn(`Received task switch request to item ${nextTask.item} with version ${targetItemVersion} and could not find a compatible task player. We ignored the request.`);
    return;
  }
  
  getScoringResult(sendingWindow)
  stopTask(sendingWindow);
  playerCatalog.show(compatiblePlayer.id);
  startTask(nextTask, compatiblePlayer.frameWindow);
  return;

}

function processShinyTaskSwitchRequest(
  nextTask: TaskIdentification,  
  itemCatalog: ItemCatalog, 
  playerCatalog: PlayerCatalog) : void 
{
  console.log(nextTask);
  const targetItemVersion = itemCatalog.getVersion(nextTask.item);
  if (targetItemVersion === undefined) {
    console.warn(`Received task switch request to unknown item ${nextTask.item}. We ignored the request.`);
    return;
  }

  // const compatiblePlayer = getCompatiblePlayer(advisedPlayerId, targetItemVersion, {id: sendingPlayerId, frameWindow: sendingWindow}, playerCatalog);
  const compatiblePlayer = playerCatalog.findCompatiblePlayer(targetItemVersion);
  if (compatiblePlayer === undefined) {
    console.warn(`Received task switch request to item ${nextTask.item} with version ${targetItemVersion} and could not find a compatible task player. We ignored the request.`);
    return;
  }
  
  // stopTask(sendingWindow);
  playerCatalog.doToAll(targetWindow => {
    stopTask(targetWindow);
  });
  playerCatalog.show(compatiblePlayer.id);
  startTask(nextTask, compatiblePlayer.frameWindow);
  return;
}
 
/**
 * Load all required items and start the first task as advised by the task sequencer.
 */
function loadItemsAndStartFirstTask(
  configuration: AssessmentConfiguration, 
  mathJaxCdnUrl: string | undefined,
  playerCatalog: PlayerCatalog, 
  itemCatalog: ItemCatalog,
  taskSequencer: TaskSequencer,
) : void {
  Promise.resolve()
    .then(() => installAllItems(configuration, mathJaxCdnUrl, playerCatalog, itemCatalog))
    .then(() => {
      const firstTask = taskSequencer.firstTask();
      if (firstTask === undefined) {
        throw new Error(`Invalid task sequencer configuration blocks starting the first task.`);
      }
      window.postMessage(JSON.stringify({eventType: "itemsLoadedInPlayer", playerCount: playerCatalog.getPlayerIds().length}),"*");
      findCompatiblePlayerAndStartTask(firstTask, playerCatalog, itemCatalog)
    })
    .catch((error) => {
      console.warn(`Could not properly initialize items and start first task: ${error.message}`);
    });
}

/**
 * Build a promise that installs all items contained in the given assessment configuration.
 */
function installAllItems(
  assessmentConfiguration: AssessmentConfiguration, 
  mathJaxCdnUrl: string | undefined,
  playerCatalog: PlayerCatalog,
  itemCatalog: ItemCatalog
  ) : Promise<void[]> 
{ 
  return Promise.all(
      assessmentConfiguration.tasks
        .map((taskConfiguration) => taskConfiguration.item)
        .filter(onlyUnique)
        .filter((itemName) => !itemCatalog.isRegistered(itemName))
        .map((itemName) => installItem(itemName, mathJaxCdnUrl, playerCatalog, itemCatalog))
  ); 
}

/**
 * Is the given index the first occurrence of the given value in the given array?
 * 
 * Using this method in a filter on an array will drop out all duplicates. 
 */
 function onlyUnique<T>(value: T, index: number, all: T[]) : boolean {
  return all.indexOf(value) === index;
}

/**
 * Build a promise that downloads the configuration for the item with the given name and installs it in the CBA runtime.
 */
function installItem(
  itemName: string, 
  mathJaxCdnUrl: string | undefined, 
  playerCatalog: PlayerCatalog, 
  itemCatalog: ItemCatalog) : Promise<void> {
  const itemRootPathPrefix = `../items/${itemName}`;

  return downloadItemConfig(itemName)
    .then((itemConfiguration) => {
      itemCatalog.register(itemConfiguration.name, itemConfiguration.runtimeCompatibilityVersion);
      playerCatalog.doToAllCompatible(itemConfiguration.runtimeCompatibilityVersion, (targetWindow) => sendMessageToTaskPlayer(targetWindow, {
        eventType: 'addItem', 
        itemConfig: itemConfiguration, 
        resourcePath: `${itemRootPathPrefix}/resources`,
        externalResourcePath: `${itemRootPathPrefix}/external-resources`,
        libraryPathsMap: { MathJax: mathJaxCdnUrl === undefined ? 'math-jax unknown' : mathJaxCdnUrl}
      }));
    })
    .catch((error) => {
      throw new Error(`Could not download configuration for item ${itemName}: ${error.message}`);
    })
}


/**
 * Start the given task on a compatible player and make the player visible.
 */
function findCompatiblePlayerAndStartTask(
  startAdvice: { firstTask: TaskIdentification, playerId? : string},
  playerCatalog: PlayerCatalog, 
  itemCatalog: ItemCatalog
) : void 
{
  const itemVersion = itemCatalog.getVersion(startAdvice.firstTask.item);
  if (itemVersion === undefined) {
    throw new Error(`Could not find item ${startAdvice.firstTask.item}.`);
  }

  const compatiblePlayer = getCompatiblePlayer(startAdvice.playerId, itemVersion, undefined, playerCatalog);
  if (compatiblePlayer === undefined) {
    throw new Error(`Could not find compatible player for item ${startAdvice.firstTask.item} with version ${itemVersion}.`);
  }

  playerCatalog.show(compatiblePlayer.id);
  startTask(startAdvice.firstTask, compatiblePlayer.frameWindow);
}

/**
 * Do the initial steps once the task player is ready: 
 *  - Assign a trace context id.
 *  - Configure the transmission channel for the trace log data.
 *  - Show a login box.
 */


 function initializeSessionAndShowLogin(
   targetWindow: MessageEventSource, 
   logTransmissionConfig: LogTransmissionConfiguration | undefined, 
   playerCatalog: PlayerCatalog) {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'setTraceContextId', contextId: buildTraceContextId()});
  
  // If no log transmission channel is configured we simply keep the default (i.e. log to console)
  if (logTransmissionConfig !== undefined) {
    sendMessageToTaskPlayer(targetWindow, {
      eventType: 'setTraceLogTransmissionChannel', 
      channel: 'http', interval: logTransmissionConfig.interval, 
      httpTimeout: logTransmissionConfig.httpTimeout, 
      transmitUrl: logTransmissionConfig.transmitUrl })
  }
  else{
    sendMessageToTaskPlayer(targetWindow, {
      eventType: 'setTraceLogTransmissionChannel', 
      channel: 'postMessage', 
      interval: 5000,
      targetOrigin: '*', 
      targetWindowType: "parent"});
  }
  
  if (playerCatalog.allPlayersReady()) {
    const targetPlayer = playerCatalog.getPlayerId(targetWindow);
    if (targetPlayer === undefined) {
      console.warn(`Received ready request from unknown task player frame. This is an internal error. The initial login dialog might be unstable.`);
    } else {
      playerCatalog.show(targetPlayer);
    }
    showLogin(targetWindow);
  }
}


/**
* Establish ourselves as task sequencer in CBA runtime.
 */
function setScalingConfiguration(targetWindow: MessageEventSource, sc :ScalingConfiguration) {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'setScalingConfiguration', ...sc})
}

/**
* Establish ourselves as task sequencer in CBA runtime.
 */
function setTaskSequencer(targetWindow: MessageEventSource) {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'setTaskSequencer', targetOrigin: window.location.origin, targetWindowType: 'parent'})
}

/**
 * Stop the running task in the CBA runtime.
 */
function stopTask(targetWindow: MessageEventSource) : void {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'stopTask'});
}

/**
 * Start a task in the CBA runtime.
 */
function startTask(toStart: TaskIdentification, targetWindow: MessageEventSource) : void {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'startTask', item: toStart.item, task: toStart.task, scope: toStart.scope});
}

/**
 * Request scoring result.
 */
function getScoringResult(targetWindow: MessageEventSource) : void {
  sendMessageToTaskPlayer(targetWindow, { eventType: 'getScoringResult'});
}

/**
 * Set the user ID in the CBA runtime.
 */
 function setUserId(userId: string, targetWindow: MessageEventSource) : void {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'setUserId', id: userId});
}

/**
 * Log out the current user.
 */
function logout(targetWindow: MessageEventSource) : void {
  sendMessageToTaskPlayer(targetWindow, {eventType: 'logout'});
}

/**
 * Trigger the login box in the CBA runtime.
 */
function showLogin(targetWindow: MessageEventSource, ) {
  sendMessageToTaskPlayer(targetWindow, {eventType: "showLogin", titleLabel: "Placeholder for Login", fieldLabel: "Please enter anything (nickname) ", buttonLabel: "Start" });
}

/**
 * Build a unique trace context id. 
 */
function buildTraceContextId() : string {
  return v4();
}

/**
 * Get the id of a compatible player.
 * 
 * Return the advised player if that exists and is compatible. 
 * Otherwise return the player of the sending window if that is given and is compatible. 
 * Otherwise pick any compatible task player.
 * 
 * We return undefined if no compatible task player is registered.
 */
function getCompatiblePlayer(
  advisedPlayerId: string | undefined, 
  itemVersion: string,
  sendingPlayer: { id: string, frameWindow: MessageEventSource} | undefined, 
  playerCatalog: PlayerCatalog) 
  : { id: string, frameWindow: MessageEventSource } | undefined 
{
  
  if (advisedPlayerId !== undefined && playerCatalog.isCompatibleById(itemVersion, advisedPlayerId)) {
    const frameWindow = playerCatalog.getFrameWindow(advisedPlayerId);
    if (frameWindow === undefined) {
      console.error(`Unexpected failure to find frame for registered player ${advisedPlayerId}. We try to find another compatible one.`);
    } else {
      return { id: advisedPlayerId, frameWindow: frameWindow };
    }
  }

  if (sendingPlayer !== undefined && playerCatalog.isCompatibleById(itemVersion, sendingPlayer.id)) {
    return sendingPlayer;
  }

  const someCompatiblePlayer = playerCatalog.findCompatiblePlayer(itemVersion);
  return someCompatiblePlayer === undefined ? undefined : { id: someCompatiblePlayer.id, frameWindow: someCompatiblePlayer.frameWindow };
}


/**
 * Get the advised player if that is given and registered.
 * Otherwise return the given triggering player. 
 */
function getTargetPlayer(
    advisedPlayerId: string | undefined, 
    sendingPlayerId: string, 
    sendingWindow: MessageEventSource, 
    playerCatalog: PlayerCatalog) 
    : { id: string, frameWindow:MessageEventSource } 
{
  if (advisedPlayerId === undefined) {
    return { id: sendingPlayerId, frameWindow: sendingWindow };
  }

  const advisedFrame = playerCatalog.getFrameWindow(advisedPlayerId);
  if (advisedFrame === undefined) {
    console.log(`Advised player for request is not regitered. We use the triggering player instead.`);
    return { id: sendingPlayerId, frameWindow: sendingWindow }
  }

  return { id: advisedPlayerId, frameWindow: advisedFrame}
}


