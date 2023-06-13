/**
 * Asynchronous methods that download files and provide their content as proper structures.
 */

// ----------------- public API --------------------------------------------------------------

/**
 * Return a promise that downloads the controller configuration.
 */
 export function downloadControllerConfig() : Promise<ControllerConfiguration> {
  const fullConfigFileName = `./controller/config.json`;
  return sendJsonDownloadRequest(fullConfigFileName).then(
    (response) => {
      if(!isControllerConfiguration(response)) {
        throw new Error(`Controller configuration is invalid: ${JSON.stringify(response)}`);
      }
      console.log(`Received controller configuration`, response);
      return response;
    }
  );
}


/**
 * Return a promise that downloads the assessment configuration.
 */
export function downloadAssessmentConfig() : Promise<AssessmentConfiguration> {
  const fullConfigFileName = `./assessments/config.json`;
  return sendJsonDownloadRequest(fullConfigFileName).then(
    (response) => {
      if(!isAssessmentConfiguration(response)) {
        throw new Error(`Assessment configuration is invalid: ${JSON.stringify(response)}`);
      }
      if (response.tasks.length < 1) {
        throw new Error(`Assessment configuration contains no tasks: ${JSON.stringify(response)}`);
      }
      console.log(`Received assessment configuration`, response);
      return response;
    }
  );
}


/**
 * Return a promise that downloads the item configuration for the given item.
 *
 *  The corresponding *.json file must have this name with .json appended as extension.
 */
export function downloadItemConfig(itemName : string) : Promise<ItemConfiguration> {
  const fullConfigFileName = `./items/${itemName}/config.json`;
  return sendJsonDownloadRequest(fullConfigFileName).then(
    (response) => {
      if(!isItemConfiguration(response)) {
        throw new Error(`Configuration of ${itemName} is invalid: ${JSON.stringify(response)}`);
      }
      console.log(`Received configuration of ${itemName}`, response);
      return response;
    }
  );
}


export function extractScalingConfigurationFromQuery() :ScalingConfiguration{
  let sc :any = {scalingMode: "scale-up-down", alignmentHorizontal: "center", alignmentVertical: "center"};
  return {...sc, ...extractFromQuery(["scalingMode", "alignmentHorizontal", "alignmentVertical"])};
}

export function extractUserIdFromQuery(_q :string) :string{
  let q = _q.length ? _q : "session";
  return extractFromQuery([q])[q] ?? "default";
}
/**
 * The content of the assessment configuration file.
 */
export interface AssessmentConfiguration {
  tasks: TaskIdentification[]
}

export interface TaskIdentification {
  item: string, 
  task: string, 
  scope: string
}

/**
 * The content of an item configuration file (as far as we need it).
 */
export interface ItemConfiguration {
  runtimeCompatibilityVersion: string,
  name: string
}

/**
 * The content of the controller configuration file.
 */
export interface ControllerConfiguration {
  traceLogTransmission?: LogTransmissionConfiguration
  mathJaxCdnUrl?: string,
  itemSize?: {
    height: number,
    width: number
  },
  players: PlayerConfiguration[],
  showPlayerInfo: boolean
}

export interface LogTransmissionConfiguration {
  transmitUrl: string,
  interval: number, 
  httpTimeout: number, 
}

export interface PlayerConfiguration {
  playerId: string,
  runtimeVersion: string,
  frameContentFile: string,
}

export interface ScalingConfiguration {
  scalingMode: string, 
  alignmentHorizontal: string, 
  alignmentVertical: string
}


// ----------------- private stuff --------------------------------------------------------------

/**
 * Return a Promise that processes a GET request for the given file.
 */
function sendJsonDownloadRequest(filename : string) : Promise<any> {
  return new Promise((resolve, reject) => {
    const xhttp = new XMLHttpRequest();
    xhttp.responseType = 'json';
    xhttp.onload = () => resolve(xhttp.response);
    xhttp.onerror = () => reject(xhttp.statusText);
    xhttp.open('GET', filename, true);
    xhttp.send();
  });
}

function extractFromQuery(params :Array<string>){
  let result :any = {};
  if(window.document.location.search.length){
    try {
      document.location.search
      .replace('?', '')
      .split('&')
      .forEach((a) => {
        let tmp = a.split('=');
        if(tmp.length===2 && params.indexOf(tmp[0])>=0)
          result[tmp[0]] = tmp[1];
      });
    } catch (error) {
      console.error("error parsing query string: " + error);
    }
  }
  return result;
}

/**
 * Runtime type checker for AssessmentConfiguration candidates.
 */
 function isAssessmentConfiguration(candidate: any) : candidate is AssessmentConfiguration {
  try {
    return candidate.tasks && Array.isArray(candidate.tasks) && candidate.tasks.every(isTaskIdentification); 
  }
  catch(error) {
    return false;
  }
}

/**
 * Runtime type checker for TaskIdentification candidates.
 */
function isTaskIdentification(candidate: any) : candidate is TaskIdentification {  
  try {
    return (
      candidate.item && typeof candidate.item === 'string' &&
      candidate.task && typeof candidate.task === 'string' &&
      candidate.scope && typeof candidate.scope === 'string' 
    );
  }
  catch(error) {
    return false;
  }
}

/**
 * Runtime type checker for ItemConfiguration candidates.
 * 
 * We just check some 'marker' members. 
 */
 function isItemConfiguration(candidate: any) : candidate is ItemConfiguration {  
  try {
    return (
      candidate.runtimeCompatibilityVersion && typeof candidate.runtimeCompatibilityVersion === 'string' &&
      candidate.name && typeof candidate.name === 'string'
    );
  }
  catch(error) {
    return false;
  }
}

/**
 * Runtime type checker for ControllerConfiguration candidates.
 */
 function isControllerConfiguration(candidate: any) : candidate is ControllerConfiguration {  
  try {
    return (
        candidate.traceLogTransmission === undefined || isLogTransmissionConfiguration(candidate.traceLogTransmission)
      ) && (
        candidate.mathJaxCdnUrl === undefined || 
        (
          candidate.mathJaxCdnUrl && typeof candidate.mathJaxCdnUrl === 'string'
        )      
      ) && (
        candidate.itemSize === undefined ||
        (
          candidate.itemSize.height && typeof candidate.itemSize.height === 'number' &&
          candidate.itemSize.width && typeof candidate.itemSize.width === 'number'
        )
      ) && (
        candidate.players && Array.isArray(candidate.players) && candidate.players.every(isPlayerConfiguration)
      ) && (
        typeof candidate.showPlayerInfo === 'boolean'
      )
      ;
  }
  catch(error) {
    return false;
  }
}

/**
 * Runtime type checker for LogTransmissionConfiguration candidates.
 */
 function isLogTransmissionConfiguration(candidate: any) : candidate is LogTransmissionConfiguration {  
  try {
    return (
          candidate.transmitUrl && typeof candidate.transmitUrl === 'string' &&
          candidate.interval && typeof candidate.interval === 'number' &&
          candidate.httpTimeout && typeof candidate.httpTimeout === 'number'
    );
  }
  catch(error) {
    return false;
  }
}

/**
 * Runtime type checker for PlayerConfiguration candidates.
 */
 function isPlayerConfiguration(candidate: any) : candidate is PlayerConfiguration {  
  try {
    return (
      candidate.playerId && typeof candidate.playerId === 'string' &&
      candidate.runtimeVersion && typeof candidate.runtimeVersion === 'string' &&
      candidate.frameContentFile && typeof candidate.frameContentFile === 'string' 
    );
  }
  catch(error) {
    return false;
  }
}
