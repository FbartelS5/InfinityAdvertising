import { LightningElement, wire, track, api } from "lwc";
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Import the schema
import ACCOUNT_NAME from "@salesforce/schema/Categorie_reservee__c.Name";
import PARENT_ACCOUNT_NAME from "@salesforce/schema/Account.Parent.Name";


// Import Apex
import getAllParentAccounts from "@salesforce/apex/DynamicCategorieController.getAllParentAccounts";
import getChildAccounts from "@salesforce/apex/DynamicCategorieController.getChildAccounts";

import getuniversedetails from "@salesforce/apex/DynamicCategorieController.getuniversedetails";

// Global Constants
const COLS = [
    { fieldName: "Name", label: "Categorie Name" },
];

export default class categorie_request extends LightningElement {
    gridColumns = COLS;
    isLoading = true;
    gridData = [];
    @track selectedRows = [];
    @track universalList = [];
        
    // Send selectedValue back to Flow
    @api selectedIdList;
    @api selectedraonIdList;
    @api selectedraonIdListuni;

    connectedCallback() {
        this.getUniversalList();
    }

    getUniversalList(){
        try {
            //method to get cycle count & lines information from backend
            getuniversedetails().then(result => {
                //Add the result to list
                this.universalList = result;
                console.log('universalList->'+JSON.stringify(this.universalList));
            }).catch(error => {
                console.log('error->'+JSON.stringify(error));
            });
        } catch (e) {
            console.error(e);
            console.error('e.name => ' + e.name );
            console.error('e.message => ' + e.message );
            console.error('e.stack => ' + e.stack );
        }
    }



    handleRowSelection() {
           console.log('js>'+JSON.Stringify(selectedRows));
           //var selectRows = this.template.querySelector('lightning-tree-grid').getSelectedRows();
    }

    
    handleSelectLeft(event){
        
        try {



            //get the single serail number selected on LHS table
            var rayonId = event.currentTarget.dataset.id;
            var uId = event.currentTarget.dataset.uid;
            var varUniversalList= this.universalList;
            var varUpdateRayonListcheckedonly = [];

         
           console.log(rayonId);
           console.log(uId);

           for(var i=0;i<varUniversalList.length;i++){
               
            var varRayonList = varUniversalList[i].rayonlist;

            var varUpdateRayonList = [];


            for(var j = 0;j< varRayonList.length;j++){

                var ser = varRayonList[j];
                if(ser.universeID == uId && ser.rayonID == rayonId){
                        
                    ser = {rayonID:ser.rayonID,isChecked:!ser.isChecked,name:ser.name,universeID:ser.universeID}; 

                }
                if(ser.isChecked)
                {
                    varUpdateRayonListcheckedonly.push(ser.rayonID);

                }

                varUpdateRayonList.push(ser);

            }
            var rayontoflow=[];
            if(varUpdateRayonListcheckedonly != undefined && varUpdateRayonListcheckedonly != '' && varUpdateRayonListcheckedonly != null && varUpdateRayonListcheckedonly.length>0 )
            {
                rayontoflow=this.removeDuplicates(varUpdateRayonListcheckedonly);
                
            }

            varUniversalList[i].rayonlist = varUpdateRayonList;
            console.log('CHECK ONLY RAYON ->'+JSON.stringify(rayontoflow));

            const attributeChangeEvent = new FlowAttributeChangeEvent('selectedraonIdList',rayontoflow);
            this.dispatchEvent(attributeChangeEvent);

        
        }

        this.universalList = varUniversalList;


        console.log('handleSelectLeft this.universalList->'+JSON.stringify(this.universalList));


        } catch (e) {
            console.error(e);
            console.error('e.name => ' + e.name );
            console.error('e.message => ' + e.message );
            console.error('e.stack => ' + e.stack );
        }
        
    }

    removeDuplicates(arr) {
        return arr.filter((item, 
            index) => arr.indexOf(item) === index);
    }



    handleShow(event){
        
        try {
            //Get the cycle count line id to display its child component
            var unId= event.currentTarget.dataset.id;
            var varUniversalList= this.universalList;
            var updateToUList = [];

            for(var i=0;i<varUniversalList.length;i++){
               
                var varUItem = varUniversalList[i];

                // if ccLineId matches in list then update the isChecked value to toggle 
                //if cycle count line is Non-Tracked type then never show its child component
                if(varUItem.universeID == unId){

                    varUItem.isShown = !varUItem.isShown;
                  
                }
                updateToUList.push(varUItem);
            }
            this.universalList = updateToUList;

            console.log('handleShow this.universalList->'+JSON.stringify(this.universalList));
        
        } catch (e) {
            console.error(e);
            console.error('e.name => ' + e.name );
            console.error('e.message => ' + e.message );
            console.error('e.stack => ' + e.stack );
        }
        
        
    }
}