import {AssessmentConfiguration} from "../utils/FileDownload"
import { TaskRequestDetails } from "./MessageReceiver";
import { TaskIdentification } from "../utils/FileDownload";
import PlayerCatalog from "../runtime/PlayerCatalog";

/**
 * The component making all next/previous/cancel task decisions. 
 * 
 * We keep a memory of available tasks and the currently running task. 
 * This implementation does not take the task player instances into account
 * and does not advise on the next task player to use.
 * 
 * With no task player advice the controller
 * sticks to the task player which was used before
 * (if the player is able to run the requested item)
 * or picks some other compatible player. 
 */
export default class TaskSequencer {
  private currentTaskIndex : number | 'not set' = 'not set';
  private tasks : TaskIdentification[] = [];

  public initialize(assessmentConfiguration: AssessmentConfiguration, playerCatalog: PlayerCatalog) : void {
    this.currentTaskIndex = 0;
    this.tasks = assessmentConfiguration.tasks;
  }

  public firstTask() : { firstTask: TaskIdentification, playerId?: string } | undefined {
    this.currentTaskIndex = 0;
    return this.tasks.length < 1 ? undefined : { firstTask: this.tasks[0] };
  }

  public cancel(sendingPlayerId: string) : Decision {
    return { type: 'login'};
  }

  public nextTask(sendingPlayerId: string) : Decision {
    return this.switchAndReturnTask((currentIndex) => currentIndex + 1, 'no next task');
  }

  public backTask(sendingPlayerId: string) : Decision {
    return this.switchAndReturnTask((currentIndex) => currentIndex - 1, 'no previous task');
  }

  public goToTask(sendingPlayerId: string, request: TaskRequestDetails) : Decision {
    return this.switchAndReturnTask(
      (_) => this.findMatchingTask(request),
      `Task ${request.task} ${request.item === undefined ? 'with item unspecified' : ('in item ' + request.item)} and in scope ${request.scope} is not part of the assessment configuration.`);
  }

  /**
   * Calculate the index to pick using the callback, check that it is in range, switch to that task and return it. 
   */
  private switchAndReturnTask(getIndexToPick: (currentIndex : number) => number, failureMessage: string ) : Decision {
    if (this.currentTaskIndex === 'not set') {
      console.warn(`Task sequencer is not initialized properly. This blocks all task switches.`);
      return { type: 'blocked', reason: 'Task sequencer not initialized properly.' };
    }
    const indexToPick = getIndexToPick(this.currentTaskIndex);
    if (indexToPick < 0 || indexToPick > this.tasks.length - 1) return { type: 'blocked', reason: failureMessage };
    this.currentTaskIndex = indexToPick;
    return { type: 'taskSwitch', nextTask: this.tasks[this.currentTaskIndex]};
  }

  private findMatchingTask(request: TaskRequestDetails) : number {
    if (!request.item) return this.tasks.findIndex((candidate) => request.task === candidate.task && request.scope === candidate.scope)
    return this.tasks.findIndex((candidate) => request.item === candidate.item && request.task === candidate.task && request.scope === candidate.scope)
  }
  
}


/**
 * The decision returned at the requests like cancel, nextTask etc.
 */
export type Decision = 
  { 
    type: 'login',
    playerId?: string
  } | 
  {
    type: 'taskSwitch',
    nextTask: TaskIdentification,
    playerId?: string
  } | 
  {
    type: 'blocked'
    reason: string
  }


