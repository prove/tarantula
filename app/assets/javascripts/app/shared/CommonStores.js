/**
 *  Stores, which are needed application wide and often, are
 *  defined here.
 *
 *  For example stores needed in combobox to display user names etc.
 *
 *  Defines also utility function renderer() for stores. Function
 *  can be used directly as rendered function in comboboxes.
 *
 *  Stores are refreshed on project change (inside.rhtml).
 *
 */


/**
 *  Store Id's.
 */
var ALL_USERS_STORE = 1;
var PROJECT_USERS_STORE = 2;

var CommonStores = function() {

    /**
     *  Keep stores in array.
     */
    var stores = [];

    /**
     *  Add store to stores array with given id.
     */
    function pushStore(id, store) {
        stores.push({id: id, store: store});
    }

    /**
     *  Create renderer function usable from combobox
     */
    function createRenderer(store, displayField) {
        store.renderer = function(v) {
            r = store.getById( v);
            if(r) {
                return r.get(displayField);
            } else {
                return v;
            }
        };
    }


    return {

        /**
         *  Create, load stores and add renderer function to stores.
         */
        init: function( element) {

            var store;

            /**
             * All users
             */
            store = new Ext.data.JsonStore({
                url: createUrl('/users?include_deleted=true'),
                //root: 'data',
                fields: [
                    {name: 'id', mapping: 'dbid'},
                    {name: 'login', mapping: 'text'},
                    {name: 'realname'},
                    {name: 'deleted'}
                ],
                //id: 'id'
                id: 'dbid'
            });

            createRenderer(store, 'login');

            store.load();

            pushStore(ALL_USERS_STORE, store);


            /**
             * Users assigned to current project.
             */
            store = new Ext.data.JsonStore({
                url: createUrl('/projects/current/users'),
                //root: 'data',
                fields: [
                    {name: 'id', mapping: 'dbid'},
                    {name: 'login', mapping: 'text'},
                    {name: 'realname'},
                    {name: 'deleted'}
                ],
                id: 'dbid'
            });


            store.load();

            pushStore(PROJECT_USERS_STORE, store);

        },

        /**
         * Find store with given id.
         */
        findStore: function( id) {
            for( var i=0; i<stores.length; i++){
                if( stores[i].id == id) {
                   return stores[i].store;
                }
            }
        },


        /**
         * Reload all stores.
         * All stores are refreshed on projectchange.
         * (inside.rhtml).
         */
        reload: function() {
            for( var i=0; i<stores.length; i++) {
                stores[i].store.reload();
            }
        }
    };
}();
