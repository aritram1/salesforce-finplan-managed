import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/ChartJs1';
import getPortfolioOverviewData from '@salesforce/apex/LWCPortFolioOverViewController.getPortfolioOverviewData';
import logError from '@salesforce/apex/Logger.logError';
export default class LwcPortfolioOverview extends LightningElement {
    componentName = 'LwcPortfolioOverview';
    
    @api recordId;
    chart; chartConfig;
    chartLoaded = false;
    portfolioData = [];
    chartLabels = [];

    getConfig(){
        let config = {
            type: 'pie',
            data: {
                labels: [...this.chartLabels],
                //labels: ['Bond','EPF','FD','MF','Metal','PPF','SIP','SmallCase','Stock','TreasuryBill','ULIP','NPS'],
                datasets: [
                    {
                        data: [...this.portfolioData], //[0,0,0,3093000,0,0,0,0,1632.2,0,0,0],//
                        backgroundColor: [
                            'rgb(255, 99, 132)','rgb(255, 159, 64)','rgb(255, 205, 86)','rgb(75, 192, 192)',
                            'rgb(54, 162, 235)','rgb(54, 162, 230)','rgb(54, 162, 222)','rgb(54, 162, 56)',
                            'rgb(54, 162, 12)','rgb(54, 162, 222)','rgb(54, 162, 134)','rgb(54, 162, 1)'
                        ],
                        label: 'My Portfolio'
                    }
                ]
            },
            options: {
                responsive: false,
                plugins:{
                    legend: {
                        position: 'right'
                    }
                },
                animation: {
                    animateScale: true,
                    animateRotate: true
                }
            }
        }
        return config;
    }

    processDataAndLabels(data){
        console.log('inside processdata');
        console.log('data=>' + JSON.stringify(data));
        let _portfolioData = [];
        let _chartLabels = [];
        for(let each of data){
            _portfolioData.push(each.value);
            _chartLabels.push(each.name);
        }
        this.portfolioData = [..._portfolioData];
        this.chartLabels = [..._chartLabels];
    }

    // Lifecycle methods
    // ConnectedCallback
    // RenderedCallback

    connectedCallback(){
        // console.log('ConnectedCallback started');
        // getPortfolioOverviewData({ portfolioId : this.recordId })
        // .then((data, error)=>{
        //     if(error) throw Error('Error received:' + error);
        //     if(!data) throw Error('No data received');
        //     console.log('ConnectedCallback after getting data' + data);
        //     this.processDataAndLabels(data);
            
        //     loadScript(this, chartjs + '/Chart.min.js')
        //     .then(() =>{
        //         window.Chart.platform.disableCSSInjection = true;
        //         const ctx = this.template.querySelector('canvas.myChart').getContext('2d');
        //         console.log('Config In renderedcallback:' + JSON.stringify(this.getConfig());
        //         this.chart = new window.Chart(ctx, this.getConfig());
        //         this.chartLoaded = true;
        //         console.log('ConnectedCallback finished');
        //     })
        //     .catch(error => console.log(`Error encountered while showing chart in renderedCallback ${error}`));

        // })
        // .catch(error => {
        //     console.log('Error: ' + error);
        //     const err = `Error encountered while getting data in connectedCallback:' ${error}`;
            
        //     logError({ error : JSON.stringify(err), componentName: this.componentName })
        //     .then(()=> console.log('Error occurred while logging!'))
        //     .catch(error=> console.log(`Error caught while logging! ${error}`));
        // });
    }

    // renderedCallback loads the scripts asynchronously with data (if not loaded yet)
    renderedCallback() {
        if(this.chartLoaded) return;
        console.log('renderedcallback started');
        getPortfolioOverviewData({ portfolioId : this.recordId })
        .then((data, error)=>{
            if(error) throw Error('Error received:' + error);
            if(!data) throw Error('No data received');
            console.log('renderedcallback after getting data' + data);
            this.processDataAndLabels(data);
            console.log('this.lwcPortfolioData->' + JSON.stringify(this.portfolioData));
            console.log('this.chartLabels->' + this.chartLabels);
    
            loadScript(this, chartjs + '/Chart.min.js')
            .then(() =>{
                window.Chart.platform.disableCSSInjection = true;
                const ctx = this.template.querySelector('canvas.myChart').getContext('2d');
                console.log('Config In renderedcallback:' + JSON.stringify(this.getConfig()));
                this.chart = new window.Chart(ctx, this.getConfig());
                this.chartLoaded = true;
                console.log('renderedcallback finished');
            })
            .catch(error => console.log(`Error encountered while showing chart in renderedCallback ${error}`));

        })
        .catch(error => {
            console.log('Error: ' + error);
            const err = `Error encountered while getting data in connectedCallback:' ${error}`;
            
            logError({ error : JSON.stringify(err), componentName: this.componentName })
            .then(()=> console.log('Error occurred while logging!'))
            .catch(error=> console.log(`Error caught while logging! ${error}`));
        });

        // console.log('start renderedCallback');

        // //if(this.chartLoaded) return;
        
        // loadScript(this, chartjs + '/Chart.min.js')
        // .then(() =>{
        //     window.Chart.platform.disableCSSInjection = true;
        //     const ctx = this.template.querySelector('canvas.myChart').getContext('2d');
        //     console.log('Config In renderedcallback:' + JSON.stringify(this.chartConfig));
        //     this.chart = new window.Chart(ctx, this.chartConfig);
        //     this.chartLoaded = true;
        //     console.log('end renderedCallback');
        // })
        // .catch(error => console.log(`Error encountered while showing chart in renderedCallback ${error}`));
    }

}