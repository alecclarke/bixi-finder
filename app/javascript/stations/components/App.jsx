import React, { Component } from 'react';
import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";

class App extends Component {
  constructor () {
    super()
    this.state = {
      ip: "",
      lat: "",
      lng: "",
    }

    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleChange = this.handleInputChange.bind(this);
  }

  handleSubmit () {
    axios.get("api/stations")
      .then(response => this.setState({username: response.data.name}))
  }

  handleInputChange(event) {
    const target = event.target;

    this.setState({
      [target.name]: target.value
    });
  }

  render () {
    return (
      <div className="finder">
        <form onSubmit={this.handleSubmit}>
          <div className="form-group">
            <label>Latitude</label>
            <input type="text" value={this.state.lat} onChange={this.handleChange}/>
          </div>
          <div className="form-group">
            <label>Longitude</label>
            <input type="text" value={this.state.lng} onChange={this.handleChange}/>
          </div>
          <button type="submit" className="btn btn-primary">Find Bixi bikes</button>
        </form>
      </div>
    )
  }
}
export default App