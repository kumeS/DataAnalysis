const fs = require('fs').promises;
const path = require('path');
const logger = require('./utils/logger');

/**
 * Claude API integration for workflow generation
 * This simulates Claude API calls - in production, you would integrate with actual Claude API
 */
class ClaudeWorkflowGenerator {
  constructor() {
    this.templates = {
      'data-analysis': require('../workflows/templates/data-analysis-template.json'),
      'api-monitoring': require('../workflows/templates/api-monitoring-template.json'),
      'report-generation': require('../workflows/templates/report-generation-template.json')
    };
  }

  /**
   * Generate n8n workflow based on natural language prompt
   * @param {string} prompt - Description of desired workflow
   * @returns {Object} - n8n workflow JSON
   */
  async generateWorkflow(prompt) {
    logger.info(`Generating workflow for prompt: "${prompt}"`);
    
    // Analyze prompt to determine workflow type
    const workflowType = this.analyzePrompt(prompt);
    logger.info(`Detected workflow type: ${workflowType}`);
    
    // Get base template
    const baseTemplate = this.templates[workflowType] || this.templates['data-analysis'];
    
    // Customize template based on prompt
    const customizedWorkflow = await this.customizeWorkflow(baseTemplate, prompt);
    
    return customizedWorkflow;
  }

  /**
   * Analyze prompt to determine workflow type
   * @param {string} prompt 
   * @returns {string}
   */
  analyzePrompt(prompt) {
    const keywords = {
      'data-analysis': ['分析', 'データ', 'analysis', 'statistics', '統計'],
      'api-monitoring': ['監視', 'API', 'monitoring', 'health', 'status'],
      'report-generation': ['レポート', 'report', '報告', 'summary', 'dashboard']
    };

    for (const [type, words] of Object.entries(keywords)) {
      if (words.some(word => prompt.toLowerCase().includes(word))) {
        return type;
      }
    }

    return 'data-analysis'; // default
  }

  /**
   * Customize workflow template based on prompt
   * @param {Object} template 
   * @param {string} prompt 
   * @returns {Object}
   */
  async customizeWorkflow(template, prompt) {
    const workflow = JSON.parse(JSON.stringify(template)); // deep copy
    
    // Update workflow name and description
    workflow.name = `Generated: ${prompt.substring(0, 50)}...`;
    workflow.meta.description = `Auto-generated workflow: ${prompt}`;
    workflow.meta.createdAt = new Date().toISOString();
    
    // Customize nodes based on prompt analysis
    if (prompt.includes('CSV') || prompt.includes('データファイル')) {
      this.addCsvProcessingNode(workflow);
    }
    
    if (prompt.includes('スケジュール') || prompt.includes('定期実行')) {
      this.addScheduleNode(workflow);
    }
    
    if (prompt.includes('通知') || prompt.includes('アラート')) {
      this.addNotificationNode(workflow);
    }
    
    return workflow;
  }

  /**
   * Add CSV processing capabilities to workflow
   * @param {Object} workflow 
   */
  addCsvProcessingNode(workflow) {
    const csvNode = {
      id: `csv-processor-${Date.now()}`,
      name: 'CSV Processor',
      type: 'n8n-nodes-base.readBinaryFile',
      typeVersion: 1,
      position: [400, 200],
      parameters: {
        filePath: '={{ $json.filePath }}',
        dataPropertyName: 'csvData'
      }
    };
    
    workflow.nodes.push(csvNode);
    logger.info('Added CSV processing node to workflow');
  }

  /**
   * Add schedule trigger to workflow
   * @param {Object} workflow 
   */
  addScheduleNode(workflow) {
    const scheduleNode = {
      id: `schedule-${Date.now()}`,
      name: 'Schedule Trigger',
      type: 'n8n-nodes-base.cron',
      typeVersion: 1,
      position: [200, 200],
      parameters: {
        triggerTimes: {
          hour: 9,
          minute: 0
        }
      }
    };
    
    workflow.nodes.unshift(scheduleNode); // Add at beginning
    logger.info('Added schedule trigger to workflow');
  }

  /**
   * Add notification node to workflow
   * @param {Object} workflow 
   */
  addNotificationNode(workflow) {
    const notificationNode = {
      id: `notification-${Date.now()}`,
      name: 'Send Notification',
      type: 'n8n-nodes-base.slack',
      typeVersion: 1,
      position: [800, 200],
      parameters: {
        channel: '#general',
        text: '={{ $json.message }}'
      }
    };
    
    workflow.nodes.push(notificationNode);
    logger.info('Added notification node to workflow');
  }
}

/**
 * Generate n8n workflow from natural language prompt
 * @param {string} prompt - Workflow description
 * @param {string} outputPath - Where to save the generated workflow
 * @returns {Object} - Generated workflow
 */
async function generateWorkflow(prompt, outputPath = './workflows/generated-workflow.json') {
  const generator = new ClaudeWorkflowGenerator();
  
  try {
    const workflow = await generator.generateWorkflow(prompt);
    
    // Ensure output directory exists
    const outputDir = path.dirname(outputPath);
    await fs.mkdir(outputDir, { recursive: true });
    
    // Save workflow to file
    await fs.writeFile(outputPath, JSON.stringify(workflow, null, 2));
    logger.info(`Workflow saved to: ${outputPath}`);
    
    return workflow;
  } catch (error) {
    logger.error('Error generating workflow:', error);
    throw error;
  }
}

module.exports = {
  generateWorkflow,
  ClaudeWorkflowGenerator
};