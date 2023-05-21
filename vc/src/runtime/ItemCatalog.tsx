/**
 * The component managing all items that were downloaded already. 
 * 
 * Each item is identified by its unique name string.
 * We keep the version number for each item.
 */
export default class ItemCatalog {
  private items : ItemInfo[] = [];

  /**
   * Register an item in the catalog.
   */
  public register(name: string, version: string) : void {
    this.items.push({name: name, version: version});
  }

  /**
   * Is an item with the given name already registered in the catalog?
   */
  public isRegistered(name: string) : boolean {
    return this.findByName(name) !== undefined;
  }

  /**
   * Get the runtime version of an item.
   * 
   * We return undefined if no item with the given name was already registered.
   */
  public getVersion(name: string) : string | undefined {
    return this.findByName(name)?.version;
  }

  /**
   * Private helper: Find an item in the catalog.
   */
  private findByName(name: string) : ItemInfo | undefined {
    return this.items.find(candidate => candidate.name === name);
  }

}

/**
 * Internal item representation in the catalog.
 */
interface ItemInfo {
  name: string, 
  version: string
}


