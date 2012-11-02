/*
Define and load several stores at once.
Callback function is called when all stores has been loaded.

Stores are identified by urls...do not use same url twice in same stores object.
*/

function AppStores() {
    this.stores = [];
    this.storesLoaded = 0;
    this.callback = null;
}


// Define store to be loaded and add to load que.
// url: Data source. Also identifies store.
// fields: Array of field names to be loaded from store.
// additionalConfig: Additional config options.
AppStores.prototype.add = function( url, fields, additionalConfig) {

    config = {
        url: createUrl(url),
        root: 'data',  // Actual data is always contained in data
                       // property of returned json.
        fields: fields
    };

    Ext.apply(config, additionalConfig);

    store = new Ext.data.JsonStore(config);

    // Add store to que.
    this.stores.push( {extStore: store, appStores: this, url: url});
};

// Load all stores.
// fn: Callback function to be called, when all stores in que has been loaded.
AppStores.prototype.load = function( fn) {

    //TODO Validation: at least one store must be defined.
    this.callback = fn;

    onStoreLoadCallback = this.onStoreLoad;

    this.stores.forEach(
        function( element, index, array) {
            element.extStore.load({ callback: onStoreLoadCallback,
                                    scope: element});
        }
    );
};

// Find particular store (identified by url).
AppStores.prototype.find = function( url) {

    var appStore = null;

    this.stores.forEach(
        function( element, index, array) {
            if( element.url == url) { appStore = element;}
        }
    );

    //TODO not found, raise error
    return appStore;
};

// Callback function called on singular store load.
// When all stores have been loaded, actual callback is called.
AppStores.prototype.onStoreLoad = function( r, options, success) {

    // callback function, Scope is set to stores array element.

    this.r = r;
    this.options = options;
    this.success = success;

    this.appStores.storesLoaded += 1;

    // If all stores have been loaded...
    if( (this.appStores.storesLoaded >= this.appStores.stores.length) &&
        (this.appStores.callback)) {
        this.appStores.callback();
    }

};