import React from 'react';
import './App.css';
import MessageReceiver from './MessageReceiver';
import { configureMessageReceiver } from './Controller';
import TaskSequencer from './TaskSequencer';
import PlayerCatalog from '../runtime/PlayerCatalog';
import ItemCatalog from '../runtime/ItemCatalog';
import { ControllerConfiguration } from '../utils/FileDownload';
import PlayerFrame from '../runtime/PlayerFrame';

/**
 * The layer that sets up all components: 
 *  - The catalogs of items and task players.
 *  - The task sequencer.
 *  - The listeners in the message receiver.
 *  - The IFrames that contain the CBA runtimes with different runtime versions.
 * 
 * The 'controller' is not a component (for now). 
 * It is implemented as a set of listeners registered
 * in the message receiver.
 */
export function App(props: { messageReceiver : MessageReceiver, controllerConfiguration: ControllerConfiguration}) : JSX.Element {

  const { messageReceiver, controllerConfiguration } = props;

  // All task players that we support.
  const playersArray = controllerConfiguration.players;

  // The catalog of all the task players running in their Iframes:
  const playerCatalog : PlayerCatalog = new PlayerCatalog(playersArray.length);

  // The catalog of all items that are currently loaded to all compatible the task players:
  const itemCatalog : ItemCatalog = new ItemCatalog();

  // The task sequencer that decides which task to run next:
  const taskSequencer : TaskSequencer = new TaskSequencer();

  // Establish our behavior, i.e. our reactions to events coming in from the task players:
  configureMessageReceiver(
    messageReceiver, 
    taskSequencer, 
    playerCatalog, 
    itemCatalog, 
    controllerConfiguration);
  
  const itemHeight = controllerConfiguration.itemSize === undefined ? 768 : controllerConfiguration.itemSize.height;
  const itemWidth = controllerConfiguration.itemSize === undefined ? 1024 : controllerConfiguration.itemSize.width;

  return (
    <div className='App' >
      { playersArray.map(player => 
        <PlayerFrame
          key={player.playerId}
          itemWidth={itemWidth} 
          itemHeight={itemHeight}
          showPlayerInfo = {controllerConfiguration.showPlayerInfo}
          playerConfiguration = {player}
          playerCatalog={playerCatalog}
        />
        )
      }      
    </div>
  );
}



/**
 * Create and initialize the message receiver.
 * 
 * We start its receiving loop on the global window.
 * 
 * We create the message receiver outside of ReactDOM.render 
 * to make sure it is not created multiple times
 * which would lead to multiple listeners on the global window.
 * 
 */
export function buildMessageReceiver() : MessageReceiver {
  const result = new MessageReceiver();
  result.startReceiving();
  return result;
}

