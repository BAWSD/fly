from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import joblib
import numpy as np
from datetime import datetime
import logging
import jieba
from collections import Counter
import re

app = Flask(__name__)
CORS(app)
logging.basicConfig(level=logging.INFO)

try:
    delay_model = joblib.load('models/delay_prediction_model.pkl')
    logging.info("Delay prediction model loaded successfully.")
except:
    logging.warning("Delay model not found. Using dummy model.")
    delay_model = None

def predict_delay(features_dict):
    if delay_model is None:
        return int(np.random.normal(20, 30, 1)[0])
    try:
        feature_names = ['historical_delay_avg', 'is_weekend', 'departure_hour', 'weather_score']
        input_features = [features_dict.get(f, 0) for f in feature_names]
        prediction = delay_model.predict([input_features])[0]
        return max(0, int(prediction))
    except Exception as e:
        logging.error(f"Prediction error: {e}")
        return 0

@app.route('/predict_delay', methods=['POST'])
def predict_delay_endpoint():
    data = request.json
    flight_number = data.get('flight_number')
    features = data.get('features', {})
    if not features:
        features = {
            'historical_delay_avg': 10,
            'is_weekend': 1 if datetime.now().weekday() >= 5 else 0,
            'departure_hour': datetime.now().hour,
            'weather_score': 2
        }
    predicted_delay = predict_delay(features)
    return jsonify({
        'flight_number': flight_number,
        'predicted_delay_minutes': predicted_delay,
        'prediction_time': datetime.now().isoformat(),
        'features_used': features
    })

def extractive_summarize(text, sentence_count=2):
    sentences = re.split(r'[。！？!?]', text)
    sentences = [s.strip() for s in sentences if len(s.strip()) > 0]
    if len(sentences) <= sentence_count:
        return '。'.join(sentences) + '。'

    word_freq = Counter()
    for sent in sentences:
        words = jieba.lcut(sent)
        word_freq.update(words)

    sentence_scores = {}
    for i, sent in enumerate(sentences):
        words = jieba.lcut(sent)
        score = sum(word_freq[word] for word in words)
        sentence_scores[i] = score

    top_sentences = sorted(sentence_scores.items(), key=lambda x: x[1], reverse=True)[:sentence_count]
    top_sentences = sorted(top_sentences, key=lambda x: x[0])
    summary = '。'.join(sentences[idx] for idx, _ in top_sentences) + '。'
    return summary

@app.route('/summarize_status', methods=['POST'])
def summarize_status():
    data = request.json
    text = data.get('text', '')
    if not text:
        return jsonify({'error': 'No text provided'}), 400

    summary = extractive_summarize(text, sentence_count=2)
    return jsonify({
        'original_text': text,
        'ai_summary': summary,
        'summary_time': datetime.now().isoformat()
    })

@app.route('/generate_improvement', methods=['POST'])
def generate_improvement():
    data = request.json
    weak_objective = data.get('weakest_objective', '课程目标3')
    score = data.get('score', 0.75)
    suggestions = [
        f"针对{weak_objective}达成度较低的问题，建议在后续教学中增加相关案例的课时比重。",
        f"当前达成度为{score:.2%}，可通过增加实践环节和项目驱动式学习提升学生应用能力。",
        "建议引入更多行业专家讲座，将最新技术动态与课程内容相结合。",
        "可考虑优化考核方式，增加过程性评价，减少期末一次性考试的权重。"
    ]
    import random
    selected = random.sample(suggestions, k=2)
    return jsonify({
        'analysis': f"系统检测到{weak_objective}为薄弱环节，达成度有待提升。",
        'suggestions': selected,
        'generated_by': 'AI Analysis Service'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)