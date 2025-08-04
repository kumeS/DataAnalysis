const cron = require('cron');
const { N8nClient } = require('./n8n-client');
const logger = require('./utils/logger');

/**
 * Workflow Scheduler for automated execution
 */
class WorkflowScheduler {
  constructor() {
    this.jobs = new Map();
    this.clients = new Map();
  }

  /**
   * Schedule workflow execution
   * @param {string} workflowId - Workflow ID
   * @param {string} cronExpression - Cron expression
   * @param {string} n8nUrl - n8n instance URL
   * @param {string} apiKey - API key
   * @param {Object} data - Data to pass to workflow
   */
  scheduleWorkflow(workflowId, cronExpression, n8nUrl, apiKey, data = {}) {
    const jobKey = `${workflowId}-${Date.now()}`;
    
    // Create n8n client if not exists
    if (!this.clients.has(n8nUrl)) {
      this.clients.set(n8nUrl, new N8nClient(n8nUrl, apiKey));
    }
    const client = this.clients.get(n8nUrl);

    // Create cron job
    const job = new cron.CronJob(
      cronExpression,
      async () => {
        try {
          logger.info(`Executing scheduled workflow: ${workflowId}`);
          const result = await client.executeWorkflow(workflowId, data);
          logger.info(`Scheduled execution completed: ${workflowId}`, result);
        } catch (error) {
          logger.error(`Scheduled execution failed: ${workflowId}`, error);
        }
      },
      null, // onComplete
      false, // start immediately
      'Asia/Tokyo' // timezone
    );

    // Store job
    this.jobs.set(jobKey, {
      job,
      workflowId,
      cronExpression,
      n8nUrl,
      createdAt: new Date()
    });

    // Start job
    job.start();
    
    logger.info(`Scheduled workflow ${workflowId} with cron: ${cronExpression}`);
    return jobKey;
  }

  /**
   * Stop scheduled workflow
   * @param {string} jobKey 
   */
  stopScheduledWorkflow(jobKey) {
    const jobInfo = this.jobs.get(jobKey);
    if (jobInfo) {
      jobInfo.job.stop();
      this.jobs.delete(jobKey);
      logger.info(`Stopped scheduled workflow: ${jobInfo.workflowId}`);
      return true;
    }
    return false;
  }

  /**
   * List all scheduled workflows
   * @returns {Array}
   */
  listScheduledWorkflows() {
    const workflows = [];
    for (const [jobKey, jobInfo] of this.jobs) {
      workflows.push({
        jobKey,
        workflowId: jobInfo.workflowId,
        cronExpression: jobInfo.cronExpression,
        n8nUrl: jobInfo.n8nUrl,
        createdAt: jobInfo.createdAt,
        isRunning: jobInfo.job.running
      });
    }
    return workflows;
  }

  /**
   * Update schedule for existing workflow
   * @param {string} jobKey 
   * @param {string} newCronExpression 
   */
  updateSchedule(jobKey, newCronExpression) {
    const jobInfo = this.jobs.get(jobKey);
    if (jobInfo) {
      // Stop old job
      jobInfo.job.stop();
      
      // Create new job with updated schedule
      const newJob = new cron.CronJob(
        newCronExpression,
        jobInfo.job.cronTime.callback,
        null,
        false,
        'Asia/Tokyo'
      );
      
      // Update job info
      jobInfo.job = newJob;
      jobInfo.cronExpression = newCronExpression;
      
      // Start new job
      newJob.start();
      
      logger.info(`Updated schedule for workflow ${jobInfo.workflowId}: ${newCronExpression}`);
      return true;
    }
    return false;
  }
}

// Global scheduler instance
const scheduler = new WorkflowScheduler();

/**
 * Schedule workflow execution
 * @param {string} workflowId 
 * @param {string} cronExpression 
 * @param {string} n8nUrl 
 * @param {string} apiKey 
 * @param {Object} data 
 */
async function scheduleWorkflow(workflowId, cronExpression, n8nUrl = process.env.N8N_URL, apiKey = process.env.N8N_API_KEY, data = {}) {
  if (!n8nUrl || !apiKey) {
    throw new Error('N8N_URL and N8N_API_KEY environment variables are required');
  }
  
  return scheduler.scheduleWorkflow(workflowId, cronExpression, n8nUrl, apiKey, data);
}

/**
 * Create a web server for schedule management
 */
function createScheduleServer(port = 3000) {
  const express = require('express');
  const app = express();
  
  app.use(express.json());
  
  // List scheduled workflows
  app.get('/schedules', (req, res) => {
    const workflows = scheduler.listScheduledWorkflows();
    res.json(workflows);
  });
  
  // Create new schedule
  app.post('/schedules', (req, res) => {
    const { workflowId, cronExpression, n8nUrl, apiKey, data } = req.body;
    
    try {
      const jobKey = scheduler.scheduleWorkflow(workflowId, cronExpression, n8nUrl, apiKey, data);
      res.json({ success: true, jobKey });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });
  
  // Delete schedule
  app.delete('/schedules/:jobKey', (req, res) => {
    const { jobKey } = req.params;
    const success = scheduler.stopScheduledWorkflow(jobKey);
    
    if (success) {
      res.json({ success: true });
    } else {
      res.status(404).json({ error: 'Schedule not found' });
    }
  });
  
  // Update schedule
  app.put('/schedules/:jobKey', (req, res) => {
    const { jobKey } = req.params;
    const { cronExpression } = req.body;
    
    const success = scheduler.updateSchedule(jobKey, cronExpression);
    
    if (success) {
      res.json({ success: true });
    } else {
      res.status(404).json({ error: 'Schedule not found' });
    }
  });
  
  app.listen(port, () => {
    logger.info(`Schedule server running on port ${port}`);
  });
  
  return app;
}

module.exports = {
  WorkflowScheduler,
  scheduleWorkflow,
  createScheduleServer,
  scheduler
};