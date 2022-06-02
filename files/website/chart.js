var POINT_Y_PREFIX = "$";
var POINT_X_PREFIX = "";
var days = ["Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"]; //x axes
var offers = [
	{ x: moment("2017-07-08T06:15:02-0600"), y: 75000, r: 10, name: "Startup" },
	{ x: moment("2021-07-08T06:15:02-0600"), y: 100000, r: 10, name: "Startup" },
	{ x: moment("2022-07-08T06:15:02-0600"), y: 125000, r: 10, name: "Startup" },
]; //y axes
var offers2 = [
	{ x: moment("2018-07-08T06:15:02-0600"), y: 75000, r: 10, name: "Bank" },
	{ x: moment("2020-07-08T06:15:02-0600"), y: 100000, r: 10, name: "Bank" },
	{ x: moment("2022-05-08T06:15:02-0600"), y: 125000, r: 10, name: "Bank" },
]; //y axes
var ctx = document.getElementById("myChart").getContext("2d");
var myChart = new Chart(ctx, {
	type: "bubble", //This is a line chart
	data: {
		datasets: [
			{
				label: "Startups",
				data: offers, //y-axes data
				borderColor: "blue",
				fill: false,
			},
			{
				label: "Banks",
				data: offers2, //y-axes data
				borderColor: "orange",
				fill: false,
			},
		],
	},
	options: {
		scales: {
			xAxes: [
				{
					scaleLabel: {
						display: false,
						labelString: "X_AXIS",
					},
					ticks: {
						callback: function (value, index, values) {
							return POINT_X_PREFIX + moment(value).format("DD-MM-YYYY");
						},
					},
				},
			],
			yAxes: [
				{
					scaleLabel: {
						display: true,
						labelString: "Salary",
					},
					ticks: {
						beginAtZero: true,
						callback: function (value, index, values) {
							return POINT_Y_PREFIX + value.toLocaleString();
						},
					},
				},
			],
		},
		tooltips: {
			displayColors: true,
			callbacks: {
				title: function (tooltipItem, all) {
					return [
						all.datasets[tooltipItem[0].datasetIndex].data[tooltipItem[0].index]
							.name,
					];
				},
				label: function (tooltipItem, all) {
					return [": " + POINT_Y_PREFIX + tooltipItem.yLabel.toLocaleString()];
				},
			},
		},
	},
});
