/**
 * The component managing all available task players (i.e. the available CBA runtimes in the player frames).
 * 
 * The application established multiple CBA runtimes (with different runtime versions).
 * Each CBA runtime lives in its own IFrame and runs a task player.
 * 
 * This catalog keeps track of all available task players. 
 * 
 * Each task player instance: 
 *  - Is identified by a unique id string.
 *  - Runs in a frame with a frame window that should be used to send messages to the task player instance.
 */
export default class PlayerCatalog {
  private readonly totalPlayerCount : number;
  private readonly players : PlayerInfo[] = [];
  private readonly pendingReadySignals : Set<MessageEventSource> = new Set<MessageEventSource>();  


  // ------------ public interface -----------------------------------------------

  /**
   * Build the player catalog. 
   * 
   * We need the final total count of task players a priori:
   * The controller should wait with the first login until all task players are ready 
   * to receive messages. We determine whether all task players are registered already
   * by comparing with this total number of expected task players. 
   * 
   * @param totalPlayerCount The total number of task players that will register. 
   */
  constructor(totalPlayerCount: number) {
    this.totalPlayerCount = totalPlayerCount;
  }

  /**
   * Register a new task player instance in our catalog.
   * 
   * We implicitly set the is-ready flag for the task player
   * if we already received its ready message earlier.
   */
  public registerPlayer(
    id: string, 
    frameWindow: MessageEventSource, 
    frameRef: React.MutableRefObject<HTMLIFrameElement|null>, 
    compatibilityChecker: (itemVersion: string) => boolean
    ) : void 
  {
    const newPlayer = {id, frameWindow, frameRef, isCompatible: compatibilityChecker, readyFlag: false};
    this.players.push(newPlayer);
    this.applyPendingReadySignal(newPlayer);
    if (this.totalPlayerCount < this.players.length) {
      console.warn(`Unexpected registration of another task player ${id} as number ${this.players.length}. Check the total player count: ${this.totalPlayerCount}. We might have started the first login prematurely!`)
    }

    console.info(`Registered player ${id}`);
  }


  /**
   * Process an incoming is-ready message from a task player instance.
   * 
   * If the task player instance is already registered we set its ready flag. 
   * Otherwise we memorize the message and apply it once the task player instance is registered.
   */
  public receiveReadySignal(sourceWindow: MessageEventSource) : void {
    const receivingPlayer = this.findPlayerByWindow(sourceWindow);
    if (receivingPlayer === undefined) {
      this.pendingReadySignals.add(sourceWindow);
    } else {
      receivingPlayer.readyFlag = true;
    }
  }

  /**
   * Are all task players ready to receive messages?
   */
   public allPlayersReady() : boolean {
    return this.players.length >= this.totalPlayerCount && this.players.every(candidate => candidate.readyFlag);
  }

  /**
   * Get the window of the frame where the task player with the given id is running.
   * 
   * This window may be used to send messages to the task player instance.
   *    
   * We return undefined if no task player instance is registered for the given id.
   */
  public getFrameWindow(playerId: string) : MessageEventSource | undefined {
    return this.findPlayerById(playerId)?.frameWindow;
  }


  /**
   * Get the id of the task player instance running in the given frame window.
   * 
   * We return undefined if no task player instance is registered for the given frame window.
   */
   public getPlayerId(sourceWindow: MessageEventSource) : string | undefined {
    return this.findPlayerByWindow(sourceWindow)?.id;
  }

  /**
   * Find a player that is compatible with the given item version. 
   * 
   * We return undefined if no such player is registered. 
   * If there is more than one compatbile player we return the first one
   * in registration order.
   */
  public findCompatiblePlayer(itemVersion: string) : { id: string, frameWindow: MessageEventSource } | undefined {
    return this.players.find(candidate => candidate.isCompatible(itemVersion));
  }

  /**
   * Determine whether the given item version is compatible with the given task player instance.
   * 
   * We return false if no task player for the given id is registered.
   */
  public isCompatibleById(itemVersion: string, playerId: string) : boolean | undefined {
    const playerInfo = this.findPlayerById(playerId);
    return playerInfo !== undefined && playerInfo.isCompatible(itemVersion);
  } 

  /**
   * Determine whether the given item version is compatible with the given task player instance.
   * 
   * We return false if no task player for the given window is registered.
   */
  public isCompatibleByWindow(itemVersion: string, targetWindow: MessageEventSource) : boolean | undefined {
    const playerInfo = this.findPlayerByWindow(targetWindow);
      return playerInfo !== undefined && playerInfo.isCompatible(itemVersion);
  } 
  
  /**
   * Run the given action on all registered task players.
   */
  public doToAll(action: (targetWindow: MessageEventSource) => void) {
    this.players.forEach(player => action(player.frameWindow));
  }

  /**
   * Run the given action on all registered and compatible task players.
   */
   public doToAllCompatible(itemVersion: string, action: (targetWindow: MessageEventSource) => void) {
    this.players.filter(player => player.isCompatible(itemVersion)).forEach(player => action(player.frameWindow));
  }


  /**
   * Make the given player visible to the user (i.e. make its Iframe visible).
   */
  public show(playerId: string) : void {
    this.players.forEach(player => {
      const frame : HTMLIFrameElement | null = player.frameRef.current;
      if (frame === null) {
        console.warn(`Cannot switch visibility for player ${player.id} since frame element is null.`);
        return;
      }
      frame.style.visibility = player.id === playerId ? 'visible' : 'collapse';
    })
  }

  /**
   * Get the ids of all registered task players.
   */
  public getPlayerIds() : string[] {
    return this.players.map(player => player.id);
  }

  // ------------ private methods ----------------------------------------------

  /**
   * Apply a pending is-ready message for the given player instance and 
   * drop it from the pending list. 
   * 
   * We do nothing if no is-ready message is on the pending list
   * for the given task player instance.
   */
  private applyPendingReadySignal(player: PlayerInfo) : void {
    const playerWindow : MessageEventSource = player.frameWindow;
    if (this.pendingReadySignals.has(playerWindow)) {
      player.readyFlag = true;
      this.pendingReadySignals.delete(playerWindow);
    }
  }

  /**
   * Find the task player instance info for the given task player frame window.
   */
  private findPlayerByWindow(frameWindow: MessageEventSource) : PlayerInfo | undefined {
    return this.players.find(candidate => candidate.frameWindow === frameWindow)
  }

  /**
   * Find the task player instance info for the given task player id.
   */
   private findPlayerById(playerId: String) : PlayerInfo | undefined {
    return this.players.find(candidate => candidate.id === playerId)
  }

}

/**
 * Information about a task player in the task player catalog.
 */
 interface PlayerInfo {
  id: string,
  frameWindow: MessageEventSource,
  frameRef: React.MutableRefObject<HTMLIFrameElement|null>
  readyFlag: boolean,
  isCompatible: (itemVersion: string) => boolean,
}
