import React, { Component } from "react";
import axios from "axios";
import "./App.css";
import 'bootstrap/dist/css/bootstrap.min.css';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {};

    this.handleInputChange = this.handleInputChange.bind(this);
    this.handleClick = this.handleClick.bind(this);
  }

  handleInputChange(event) {
    const target = event.target;
    const value = target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  }

  handleClick(event) {
    // The functionality for calling the api should be imported from a service.
    axios.get("api/stations", 
      { 
        params:
          {
            lat: this.state.lat,
            lng: this.state.lng,
            limit: 3,
          }
      }
    ).then(response => {
      // Mapping the response should be moved out to another method.
      this.setState({
        stations: response.data.map((station) => {
          return <li className="list-group-item" key={station.station_id}>
            {station.name} - Lat: {station.lat} Lng: {station.lng} Availability: {station.availability}
          </li>
        })
      });
    }).catch(err => console.log(err))
  }

  render() {
    return (
      <div>
        <h2>Find the closest available BIXI bike</h2>
        <div className="finder-inputs">
          <div className="form-group">
            <label>Latitude:</label>
            <input className="form-control" name="lat" type="text" onChange={this.handleInputChange} />
          </div>
          <div className="form-group">
            <label>Longitude:</label>
            <input className="form-control" name="lng" type="text" onChange={this.handleInputChange} />
          </div>
          <div className="form-group">
            <input className="btn btn-primary" type="submit" value="Submit" onClick={this.handleClick} />
          </div>  
        </div>

        <div>
          <ul className="list-group">{this.state.stations}</ul>
        </div>
      </div>
    );
  }
}
export default App