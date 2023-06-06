import React, { useEffect } from 'react';
import { PlayerConfiguration } from '../utils/FileDownload';
import PlayerCatalog from './PlayerCatalog';

/**
 * An IFrame containing a CBA runtime running a task player.
 * 
 * The component registers the task player as soon as the IFrame 
 * is available. 
 * 
 * The properties itemWidth and itemHeight specify the size of the IFrame.
 * We load the source file for the IFrame from the react-runtime subfolder.
 */
export default function PlayerFrame( props: {
    itemWidth: number, 
    itemHeight: number,
    showPlayerInfo: boolean,
    playerConfiguration: PlayerConfiguration,
    playerCatalog: PlayerCatalog
  }) : JSX.Element
{

  const { playerId, runtimeVersion, frameContentFile } = props.playerConfiguration;

  // The late-binding references to the CBA-runtime IFrame element and the containing div element:
  const frameRef: React.MutableRefObject<HTMLIFrameElement|null> = React.useRef(null);
  const divRef: React.MutableRefObject<HTMLIFrameElement|null> = React.useRef(null);
 

  // Once our frame is mounted register the player in the player catalog:
  useEffect(() => {
    const contentWindow = frameRef.current?.contentWindow;
    if (contentWindow === null || contentWindow === undefined) {
      console.warn(`Content window of task player frame is invalid!`);
      return;
    }
    props.playerCatalog.registerPlayer(playerId, contentWindow, divRef, (itemVersion) => itemVersion === runtimeVersion);
  }, [props.playerCatalog, playerId, runtimeVersion]);

  return (
    <div className='PlayerFrame' 
      ref={divRef}
      style={{position: 'absolute', top: '0px', left: '0px', borderStyle: 'none', width: '100%', height: '100%', display: 'flex', alignItems: 'baseline', justifyContent: 'center'}}
    >
      { !props.showPlayerInfo || 
        <div style={{fontSize: 'xx-small' }}>
          Current Player: {playerId }, Version: {runtimeVersion}
        </div>
      }
      <iframe
        ref={frameRef}
        style={
          { 
            width: '100%',
            height: '100%'
            // width: props.itemWidth + 'px',
            // height: props.itemHeight + 'px'
          }
        }
        title='PlayerFrame'
        src={`./react-runtime/${frameContentFile}?eventTargetWindow=parent`}       
        frameBorder="0"  
        scrolling="no"  
        className='cbaframe'
      />
    </div>
  )
}

