const axios = require('axios');
const fs = require('fs').promises;
const logger = require('./utils/logger');

/**
 * n8n API Client for workflow management
 */
class N8nClient {
  constructor(baseUrl, apiKey) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.client = axios.create({
      baseURL: baseUrl,
      headers: {
        'X-N8N-API-KEY': apiKey,
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Deploy workflow to n8n instance
   * @param {Object} workflow - Workflow JSON object
   * @returns {string} - Workflow ID
   */
  async deployWorkflow(workflow) {
    try {
      logger.info(`Deploying workflow: ${workflow.name}`);
      
      // Check if workflow already exists
      const existingWorkflow = await this.findWorkflowByName(workflow.name);
      
      if (existingWorkflow) {
        // Update existing workflow
        const response = await this.client.put(`/workflows/${existingWorkflow.id}`, workflow);
        logger.info(`Updated existing workflow: ${existingWorkflow.id}`);
        return existingWorkflow.id;
      } else {
        // Create new workflow
        const response = await this.client.post('/workflows', workflow);
        const workflowId = response.data.id;
        logger.info(`Created new workflow: ${workflowId}`);
        return workflowId;
      }
    } catch (error) {
      logger.error('Failed to deploy workflow:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Find workflow by name
   * @param {string} name 
   * @returns {Object|null}
   */
  async findWorkflowByName(name) {
    try {
      const response = await this.client.get('/workflows');
      const workflows = response.data;
      return workflows.find(w => w.name === name) || null;
    } catch (error) {
      logger.error('Failed to list workflows:', error.response?.data || error.message);
      return null;
    }
  }

  /**
   * Activate workflow
   * @param {string} workflowId 
   */
  async activateWorkflow(workflowId) {
    try {
      await this.client.post(`/workflows/${workflowId}/activate`);
      logger.info(`Activated workflow: ${workflowId}`);
    } catch (error) {
      logger.error('Failed to activate workflow:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Execute workflow manually
   * @param {string} workflowId 
   * @param {Object} data - Input data
   */
  async executeWorkflow(workflowId, data = {}) {
    try {
      const response = await this.client.post(`/workflows/${workflowId}/execute`, {
        data
      });
      logger.info(`Executed workflow: ${workflowId}`);
      return response.data;
    } catch (error) {
      logger.error('Failed to execute workflow:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Get workflow execution history
   * @param {string} workflowId 
   * @param {number} limit 
   */
  async getExecutionHistory(workflowId, limit = 10) {
    try {
      const response = await this.client.get(`/executions`, {
        params: {
          workflowId,
          limit
        }
      });
      return response.data;
    } catch (error) {
      logger.error('Failed to get execution history:', error.response?.data || error.message);
      throw error;
    }
  }
}

/**
 * Deploy workflow from file to n8n instance
 * @param {string} workflowFile - Path to workflow JSON file
 * @param {string} n8nUrl - n8n instance URL
 * @param {string} apiKey - API key
 * @returns {string} - Workflow ID
 */
async function deployWorkflow(workflowFile, n8nUrl, apiKey) {
  try {
    // Read workflow file
    const workflowData = await fs.readFile(workflowFile, 'utf8');
    const workflow = JSON.parse(workflowData);
    
    // Create n8n client
    const client = new N8nClient(n8nUrl, apiKey);
    
    // Deploy workflow
    const workflowId = await client.deployWorkflow(workflow);
    
    // Activate workflow
    await client.activateWorkflow(workflowId);
    
    logger.info(`Successfully deployed and activated workflow: ${workflowId}`);
    return workflowId;
  } catch (error) {
    logger.error('Deployment failed:', error);
    throw error;
  }
}

/**
 * Execute workflow with data
 * @param {string} workflowId 
 * @param {string} n8nUrl 
 * @param {string} apiKey 
 * @param {Object} data 
 */
async function executeWorkflow(workflowId, n8nUrl, apiKey, data = {}) {
  const client = new N8nClient(n8nUrl, apiKey);
  return await client.executeWorkflow(workflowId, data);
}

module.exports = {
  N8nClient,
  deployWorkflow,
  executeWorkflow
};