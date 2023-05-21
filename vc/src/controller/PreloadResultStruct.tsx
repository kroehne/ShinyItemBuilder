/**
 * Result structure returned by task player once resource preloading is done.
 */
export type PreloadResultStruct = PreloadSuccessResult | PreloadFailureResult;

export interface PreloadFailureResult {
    isSuccess: false,
    message: string
}

export interface PreloadSuccessResult {
    isSuccess: true,
    message: PreloadResultMessage
}

export interface PreloadResultMessage {
    images: PreloadResourceEntry[],
    videos: PreloadResourceEntry[],
    audios: PreloadResourceEntry[]
}

export interface PreloadResourceEntry {
    name: string,
    size: number,
    type: string, 
    path: string,
    isExternal: boolean,
    hadErrors: boolean
}