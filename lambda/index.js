const AWS = require('aws-sdk');

const cloudwatch = new AWS.CloudWatch();

exports.handler = async (event) => {
    const namespace = process.env.NAMESPACE || 'Demo/App';
    const metricName = process.env.METRIC_NAME || 'trigger_count';

    const params = {
        Namespace: namespace,
        MetricData: [
            {
                MetricName: metricName,
                Value: 1,
                Unit: 'Count',
                StorageResolution: 1, // High-resolution metric (1-second granularity)
                Timestamp: new Date(Date.now() - 30000) // 30 seconds in the past
            }
        ]
    };

    try {
        const result = await cloudwatch.putMetricData(params).promise();
        console.log('Successfully put metric data:', JSON.stringify(result, null, 2));

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Metric data put successfully',
                namespace: namespace,
                metricName: metricName,
                timestamp: new Date().toISOString()
            })
        };
    } catch (error) {
        console.error('Error putting metric data:', error);

        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error putting metric data',
                error: error.message
            })
        };
    }
};
