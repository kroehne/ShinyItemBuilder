import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import {App, buildMessageReceiver} from './controller/App';
import { ControllerConfiguration, downloadControllerConfig } from './utils/FileDownload';

/**
 * The entry point into the application.
 */

// We start the application rendering after fetching our controller configuration.
downloadControllerConfig()
.then((controllerConfiguration: ControllerConfiguration) => {
  // We create the message receiver here to make sure it is created exactly once:
  const messageReceiver = buildMessageReceiver();
  
  ReactDOM.render(
    <React.StrictMode>
      <App messageReceiver={messageReceiver} controllerConfiguration={controllerConfiguration} />
    </React.StrictMode>,
    document.getElementById('ee4basicsRoot')
  );  
})
.catch((error) => {
  console.warn(`Could not initialize assessment properly: ${error.message}`);
});
