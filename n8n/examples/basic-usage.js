#!/usr/bin/env node

/**
 * n8n × Claude Code 基本使用例
 * Basic usage examples for n8n × Claude Code automation
 */

const { generateWorkflow } = require('../cli/workflow-generator');
const { deployWorkflow } = require('../cli/n8n-client');
const { scheduleWorkflow } = require('../cli/scheduler');

// 環境変数の設定例
process.env.N8N_URL = process.env.N8N_URL || 'https://your-n8n-instance.com';
process.env.N8N_API_KEY = process.env.N8N_API_KEY || 'your-n8n-api-key';

async function example1_generateDataAnalysisWorkflow() {
  console.log('📊 Example 1: データ解析ワークフロー生成');
  
  try {
    const prompt = 'CSVファイルを読み込んで統計解析を行い、結果をSlackに通知するワークフロー';
    const workflow = await generateWorkflow(prompt, './examples/generated-data-analysis.json');
    
    console.log('✅ データ解析ワークフローが生成されました');
    console.log(`   ファイル: ./examples/generated-data-analysis.json`);
    console.log(`   ワークフロー名: ${workflow.name}`);
    
    return workflow;
  } catch (error) {
    console.error('❌ ワークフロー生成に失敗:', error.message);
  }
}

async function example2_deployAndActivateWorkflow() {
  console.log('🚀 Example 2: ワークフローのデプロイと有効化');
  
  try {
    const workflowFile = './examples/generated-data-analysis.json';
    const workflowId = await deployWorkflow(
      workflowFile,
      process.env.N8N_URL,
      process.env.N8N_API_KEY
    );
    
    console.log('✅ ワークフローがデプロイされました');
    console.log(`   ワークフローID: ${workflowId}`);
    
    return workflowId;
  } catch (error) {
    console.error('❌ デプロイに失敗:', error.message);
  }
}

async function example3_scheduleAutomation() {
  console.log('⏰ Example 3: ワークフローの自動スケジューリング');
  
  try {
    const workflowId = 'your-workflow-id'; // 実際のワークフローIDに置き換え
    const cronExpression = '0 9 * * *'; // 毎日午前9時
    
    const jobKey = await scheduleWorkflow(
      workflowId,
      cronExpression,
      process.env.N8N_URL,
      process.env.N8N_API_KEY,
      { dataPath: '/data/daily-metrics.csv' }
    );
    
    console.log('✅ ワークフローがスケジュールされました');
    console.log(`   ジョブキー: ${jobKey}`);
    console.log(`   実行スケジュール: ${cronExpression} (毎日午前9時)`);
    
    return jobKey;
  } catch (error) {
    console.error('❌ スケジューリングに失敗:', error.message);
  }
}

async function example4_completeAutomationPipeline() {
  console.log('🎯 Example 4: 完全自動化パイプライン');
  
  try {
    // Step 1: ワークフロー生成
    console.log('Step 1: ワークフロー生成中...');
    const prompt = 'APIの監視を行い、異常を検出したらアラートを送信し、Claude Codeで障害分析を実行';
    const workflow = await generateWorkflow(prompt, './examples/monitoring-workflow.json');
    
    // Step 2: デプロイ
    console.log('Step 2: デプロイ中...');
    const workflowId = await deployWorkflow(
      './examples/monitoring-workflow.json',
      process.env.N8N_URL,
      process.env.N8N_API_KEY
    );
    
    // Step 3: スケジュール設定
    console.log('Step 3: スケジュール設定中...');
    const jobKey = await scheduleWorkflow(
      workflowId,
      '*/5 * * * *', // 5分毎
      process.env.N8N_URL,
      process.env.N8N_API_KEY,
      { apiEndpoint: 'https://api.example.com/health' }
    );
    
    console.log('🎉 完全自動化パイプラインが構築されました！');
    console.log(`   ワークフロー: ${workflow.name}`);
    console.log(`   ID: ${workflowId}`);
    console.log(`   スケジュール: 5分毎の監視`);
    console.log(`   ジョブキー: ${jobKey}`);
    
  } catch (error) {
    console.error('❌ 自動化パイプライン構築に失敗:', error.message);
  }
}

async function example5_claudeIntegrationDemo() {
  console.log('🤖 Example 5: Claude Code統合デモ');
  
  const { ClaudeWorkflowGenerator } = require('../cli/workflow-generator');
  const generator = new ClaudeWorkflowGenerator();
  
  // 複数のプロンプトでワークフロー生成をテスト
  const prompts = [
    'データベースから売上データを取得して月次レポートを生成',
    'GitHubのPRを監視してコードレビューアラートを送信',
    'サーバーのリソース使用率を監視してスケーリング提案を作成'
  ];
  
  for (const prompt of prompts) {
    try {
      console.log(`\n📝 プロンプト: "${prompt}"`);
      const workflow = await generator.generateWorkflow(prompt);
      
      console.log(`   生成されたワークフロー: ${workflow.name}`);
      console.log(`   ノード数: ${workflow.nodes.length}`);
      console.log(`   タイプ: ${generator.analyzePrompt(prompt)}`);
      
    } catch (error) {
      console.error(`   ❌ 生成失敗: ${error.message}`);
    }
  }
}

// メイン実行関数
async function runExamples() {
  console.log('🚀 n8n × Claude Code 使用例デモ開始\n');
  
  try {
    await example1_generateDataAnalysisWorkflow();
    console.log('\n' + '='.repeat(50) + '\n');
    
    await example2_deployAndActivateWorkflow();
    console.log('\n' + '='.repeat(50) + '\n');
    
    await example3_scheduleAutomation();
    console.log('\n' + '='.repeat(50) + '\n');
    
    await example4_completeAutomationPipeline();
    console.log('\n' + '='.repeat(50) + '\n');
    
    await example5_claudeIntegrationDemo();
    
  } catch (error) {
    console.error('❌ デモ実行中にエラーが発生:', error);
  }
  
  console.log('\n🎉 デモ完了！');
  console.log('\n📖 詳細な使用方法は以下を参照:');
  console.log('   CLI: n8n-claude-cli --help');
  console.log('   ドキュメント: ./docs/');
  console.log('   設定例: ./examples/');
}

// スクリプトとして実行された場合
if (require.main === module) {
  runExamples().catch(console.error);
}

module.exports = {
  example1_generateDataAnalysisWorkflow,
  example2_deployAndActivateWorkflow,
  example3_scheduleAutomation,
  example4_completeAutomationPipeline,
  example5_claudeIntegrationDemo
};