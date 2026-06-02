# 1. Install dependencies
pip install openai anthropic google-generativeai requests

# 2. Set API keys (or create api_keys.json)
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="..."
export GOOGLE_API_KEY="..."
export DEEPSEEK_API_KEY="..."

# 3. Run on all models
python epistemic_benchmark.py --all

# 4. Run on single model
python epistemic_benchmark.py --model deepseek

# 5. With API keys file
python epistemic_benchmark.py --all --api-keys api_keys.json
