import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
import Inspector from 'react-json-inspector';


class App extends Component {

  constructor(props) {
    super(props);
    this.data= props.data;
  }


  render() {
    return (
      <div className="App">
        <header className="App-header">
          <h1 className="App-title">Qascade Container Viewer</h1>
        </header>
        <p className="js-inspector">
          <Inspector data={ this.data } />
        </p>
      </div>
    );
  }
}

export default App;
