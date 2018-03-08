import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import './json-inspector.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

var data = {"placeholder":0};

ReactDOM.render(<App data={ data } />, document.getElementById('root'));
registerServiceWorker();
