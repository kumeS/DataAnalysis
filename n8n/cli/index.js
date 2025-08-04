#!/usr/bin/env node

const { Command } = require('commander');
const { generateWorkflow } = require('./workflow-generator');
const { deployWorkflow } = require('./n8n-client');
const { scheduleWorkflow } = require('./scheduler');
const { createServer } = require('./server');
const logger = require('./utils/logger');

const program = new Command();

program
  .name('n8n-claude-cli')
  .description('n8n × Claude Code automation CLI')
  .version('1.0.0');

program
  .command('generate')
  .description('Generate n8n workflow from Claude prompt')
  .option('-p, --prompt <prompt>', 'Workflow description prompt')
  .option('-o, --output <file>', 'Output file path', './workflows/generated-workflow.json')
  .action(async (options) => {
    try {
      logger.info('Generating workflow from prompt...');
      const workflow = await generateWorkflow(options.prompt);
      logger.info(`Workflow saved to: ${options.output}`);
    } catch (error) {
      logger.error('Failed to generate workflow:', error);
      process.exit(1);
    }
  });

program
  .command('deploy')
  .description('Deploy workflow to n8n instance')
  .option('-f, --file <file>', 'Workflow JSON file')
  .option('-u, --url <url>', 'n8n instance URL')
  .option('-k, --key <key>', 'API key')
  .action(async (options) => {
    try {
      logger.info('Deploying workflow to n8n...');
      await deployWorkflow(options.file, options.url, options.key);
      logger.info('Workflow deployed successfully');
    } catch (error) {
      logger.error('Failed to deploy workflow:', error);
      process.exit(1);
    }
  });

program
  .command('schedule')
  .description('Schedule workflow execution')
  .option('-w, --workflow-id <id>', 'Workflow ID')
  .option('-c, --cron <expression>', 'Cron expression')
  .action(async (options) => {
    try {
      logger.info('Scheduling workflow...');
      await scheduleWorkflow(options.workflowId, options.cron);
      logger.info('Workflow scheduled successfully');
    } catch (error) {
      logger.error('Failed to schedule workflow:', error);
      process.exit(1);
    }
  });

program
  .command('auto')
  .description('Complete automation: generate → deploy → schedule')
  .option('-p, --prompt <prompt>', 'Workflow description')
  .option('-u, --url <url>', 'n8n instance URL')
  .option('-k, --key <key>', 'API key')
  .option('-c, --cron <expression>', 'Cron expression', '0 9 * * *')
  .action(async (options) => {
    try {
      logger.info('Starting complete automation pipeline...');
      
      // Step 1: Generate workflow
      logger.info('Step 1: Generating workflow...');
      const workflow = await generateWorkflow(options.prompt);
      
      // Step 2: Deploy workflow
      logger.info('Step 2: Deploying workflow...');
      const workflowId = await deployWorkflow('./workflows/generated-workflow.json', options.url, options.key);
      
      // Step 3: Schedule workflow
      logger.info('Step 3: Scheduling workflow...');
      await scheduleWorkflow(workflowId, options.cron);
      
      logger.info('Complete automation pipeline executed successfully!');
    } catch (error) {
      logger.error('Automation pipeline failed:', error);
      process.exit(1);
    }
  });

program
  .command('server')
  .description('Start HTTP server for webhook triggers and health checks')
  .option('-p, --port <port>', 'Server port', process.env.N8N_PORT || '3000')
  .action(async (options) => {
    try {
      const app = createServer(options.port);
      app.listen(options.port, () => {
        logger.info(`n8n × Claude Code server listening on port ${options.port}`);
      });
    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  });

program.parse();