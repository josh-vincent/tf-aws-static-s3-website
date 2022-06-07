const AWS = require('aws-sdk');
const documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = function(event, context, callback){
	const params = {
		TableName : "LinkedInOffers"
	};
	documentClient.scan(params, function(err, data){
		if(err){
		    callback(err, null);
		} else {
		const response = {
		    statusCode: 200,
		    headers: {
			    "Access-Control-Allow-Origin" : "*", // Required for CORS support to work
				"Access-Control-Allow-Credentials" : true // Required for cookies, authorization headers with HTTPS
			    },
			    body: JSON.stringify(data.Items)
		    };
		    callback(null, response);
		}
	});
}