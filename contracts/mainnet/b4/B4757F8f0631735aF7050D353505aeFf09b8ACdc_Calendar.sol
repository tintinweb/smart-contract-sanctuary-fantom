// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Calendar {
  event UpdateTitle(address username, uint calendarID, string title);
  event AddEvent(address username, uint eventID, string title);
  event UpdateEvent(address username, uint eventID, string eventTitle);
  event DeleteEvent(address username, uint eventID);

  uint public id;
  string public title;
  address public creator;

  function init(uint _id, address _creator) external {
    id = _id;
    creator = _creator;
  }

  function updateTitle(string memory _title) external {
    title = _title;
    emit UpdateTitle(msg.sender, id, title);
  }

  struct Event {
    uint id;
    address username;
    string title;
    uint startTime;
    uint endTime;
    bool isDeleted;
  }

  Event[] private events;

  mapping(uint => address) eventCreatorIndex;
  mapping(uint => mapping(uint => uint[])) monthEventsIndex;

  function addEvent(string memory eventTitle, uint startTime, uint endTime, uint year, uint month) external {
    uint eventID = events.length;
    events.push(Event(eventID, msg.sender, eventTitle, startTime, endTime, false));
    monthEventsIndex[year][month].push(eventID);
    eventCreatorIndex[eventID] = msg.sender;
    emit AddEvent(msg.sender, eventID, eventTitle);
  }

  function getAllEvents() external view returns (Event[] memory) {
    Event[] memory tmp = new Event[](events.length);

    uint counter = 0;
    for(uint i=0; i<events.length; i++) {
      if(!events[i].isDeleted) {
        tmp[counter] = events[i];
        counter++;
      }
    }

    Event[] memory result = new Event[](counter);

    for(uint i=0; i<counter; i++) {
      result[i] = tmp[i];
    }
    return result;
  }

  function getMyEvents() external view returns (Event[] memory) {
    Event[] memory tmp = new Event[](events.length);

    uint counter = 0;
    for(uint i=0; i<events.length; i++) {
      if(eventCreatorIndex[i] == msg.sender && !events[i].isDeleted) {
        tmp[counter] = events[i];
        counter++;
      }
    }

    Event[] memory result = new Event[](counter);

    for(uint i=0; i<counter; i++) {
      result[i] = tmp[i];
    }
    return result;
  }

  function updateEvent(uint eventID, string memory eventTitle) external {
    if(eventCreatorIndex[eventID] == msg.sender) {
      events[eventID].title = eventTitle;
      emit UpdateEvent(msg.sender, eventID, eventTitle);
    }
  }

  function deleteEvent(uint eventID) external {
    if(eventCreatorIndex[eventID] == msg.sender) {
      events[eventID].isDeleted = true;
      emit DeleteEvent(msg.sender, eventID);
    }
  }
}