import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/ChartJS';
import getPortfolioOverviewData from '@salesforce/apex/LWCPortFolioOverViewController.getPortfolioOverviewData';
import logError from '@salesforce/apex/Logger.logError';
export default class LwcPortfolioOverview extends LightningElement {
    chart;
    @api recordId;
    chartLoaded = false;
    portfolioData = [];

    async connectedCallback(){
        try{
            let {data, error} = await getPortfolioOverviewData({ portfolioId : this.recordId});
            if(error) throw Error(`Error encountered while getting data from getPortfolioOverviewData : ${error}`);
            this.processDataAndLabels(data);
        }
        catch(error){
            const err = `Error encountered while getting data in connectedCallback:' + ${error}`;
            console.log(err);
            await logError(err);
        }
        finally{}
    }

    // connectedCallback(){
    //     getPortfolioOverviewData({ portfolioId : this.recordId})
    //     .then((data, error)=>{
    //         if(error) throw Error('Error received:' + error);
    //         this.portfolioData = [...this.processData(data)];
    //     })
    //     .catch(error => {
    //         console.log(`Error encountered while getting data in connectedCallback:' + ${error}`);
    //     });
    // }

    processDataAndLabels(data){
        let _portfolioData = [];
        let _chartLabels = ['Id', 'SmallCase', 'Bond', 'Stock', 'T-Bills', 'ULIP', 'MF', 'EPF', 'PPF', 'FD', 'Metal'];
        for(let each of data){
            _portfolioData.push({
                'id' : each.Id,
                'smallCase' : each.FinPlan__SmallCase_Invested_Amount__c,
                'bond' : FinPlan__Bond_Investment_Amount__c,
                'stock' : FinPlan__Stock_Invested_Amount__c,
                'tBills' : FinPlan__Treasury_Bills_Invested_Amount__c,
                'ulip' : FinPlan__Ulip_Invested_Amount__c,
                'mf' : FinPlan__MF_Invested_Amount__c,
                'epf' : FinPlan__EPF_Invested_Amount__c,
                'ppf' : FinPlan__PPF_Invested_Amount__c,
                'fd' : FinPlan__FD_Invested_Amount__c,
                'metal': FinPlan__Metal_Invested_Amount__c
            });
        }
        this.portfolioData = [..._portfolioData];
        this.chartLabels = [..._chartLabels];
    }

    // async renderedCallback loads the scripts asynchronously with data (if not loaded yet)
    async renderedCallback() {
        if(this.chartLoaded) return;
        try{
            await loadScript(this, chartjs);
            this.generateChart();
            this.chartLoaded = true;
        }
        catch(error){
            console.log(`Error encountered while showing chart in renderedCallback ${error}`);
        }
        finally{}
    }

    

    generateChart(){
        const ctx = this.template.querySelector('canvas').getContext('2d');
        const chartData = {
            labels: this.chartLabels,
            datasets: [{
                label: 'Investment Dataset',
                data: this.portfolioData,
                /*
                backgroundColor: [
                    'rgba(255, 99, 132, 0.2)',
                    'rgba(54, 162, 235, 0.2)',
                    'rgba(255, 206, 86, 0.2)',
                    'rgba(75, 192, 192, 0.2)',
                    'rgba(153, 102, 255, 0.2)',
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)',
                    'rgba(54, 162, 235, 1)',
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)',
                    'rgba(153, 102, 255, 1)',
                ],
                */
                borderWidth: 1
            }]
        };
        
        // Generate the chart from processed data
        this.chart = new window.Chart(ctx, {
            type: this.getChartType(),
            data: chartData,
            options: this.getChartOptions()
        });
    }


    getChartOptions(){
        const options = {
            responsive: true,
            maintainAspectRatio: false,
            title: {
                display: true,
                text: 'Investment Portfolio'
            }
        };
        return options;
    }

    getChartType(){
        return 'pie';
    }
}