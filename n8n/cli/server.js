const express = require('express');
const { createScheduleServer } = require('./scheduler');
const logger = require('./utils/logger');

/**
 * Express server for n8n × Claude Code automation
 */
function createServer(port = process.env.N8N_PORT || 3000) {
  const app = express();
  
  app.use(express.json());
  
  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'n8n-claude-automation',
      version: require('../package.json').version
    });
  });
  
  // Readiness check endpoint
  app.get('/ready', (req, res) => {
    // Check if all required services are available
    const requiredEnvVars = ['N8N_URL', 'N8N_API_KEY'];
    const missingVars = requiredEnvVars.filter(v => !process.env[v]);
    
    if (missingVars.length > 0) {
      return res.status(503).json({
        status: 'not ready',
        error: 'Missing required environment variables',
        missing: missingVars
      });
    }
    
    res.json({
      status: 'ready',
      timestamp: new Date().toISOString()
    });
  });
  
  // Workflow trigger endpoints
  app.post('/trigger/:workflowType', async (req, res) => {
    const { workflowType } = req.params;
    const data = req.body;
    
    try {
      logger.info(`Triggering workflow type: ${workflowType}`, data);
      
      // Here you would implement the logic to trigger specific workflow types
      // This is a placeholder implementation
      const result = {
        triggered: true,
        workflowType,
        data,
        timestamp: new Date().toISOString()
      };
      
      res.json(result);
    } catch (error) {
      logger.error('Workflow trigger failed:', error);
      res.status(500).json({
        error: 'Workflow trigger failed',
        message: error.message
      });
    }
  });
  
  // Error handling middleware
  app.use((error, req, res, next) => {
    logger.error('Server error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  });
  
  return app;
}

module.exports = { createServer };