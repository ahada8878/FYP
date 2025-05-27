const UserDetails = require("../models/userDetails.js");

const getAllUserDetails = async (req, res) => {
  try {
    const userDetails = await UserDetails.find();
    res.status(200).json(userDetails);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getUserDetailsById = async (req, res) => {
  res.json(res.userDetails);
};

const createUserDetails = async (req, res) => {
  const {
    authToken,
    userName,
    selectedMonth,
    selectedDay,
    selectedYear,
    height,
    currentWeight,
    targetWeight,
    selectedSubGoals,
    selectedHabits,
    activityLevels,
    scheduleIcons,
    healthConcerns,
    levels,
    options,
    mealOptions,
    waterOptions,
    restrictions,
    eatingStyles,
    startTimes,
    endTimes,
  } = req.body;

  const userDetails = new UserDetails({
    authToken,
    userName,
    selectedMonth,
    selectedDay,
    selectedYear,
    height,
    currentWeight,
    targetWeight,
    selectedSubGoals,
    selectedHabits,
    activityLevels,
    scheduleIcons,
    healthConcerns,
    levels,
    options,
    mealOptions,
    waterOptions,
    restrictions,
    eatingStyles,
    startTimes,
    endTimes,
  });

  try {
    const newUserDetails = await userDetails.save();
    res.status(201).json(newUserDetails);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateUserDetails = async (req, res) => {
  const updatableFields = [
    "authToken",
    "userName",
    "selectedMonth",
    "selectedDay",
    "selectedYear",
    "height",
    "currentWeight",
    "targetWeight",
    "selectedSubGoals",
    "selectedHabits",
    "activityLevels",
    "scheduleIcons",
    "healthConcerns",
    "levels",
    "options",
    "mealOptions",
    "waterOptions",
    "restrictions",
    "eatingStyles",
    "startTimes",
    "endTimes",
  ];

  updatableFields.forEach((field) => {
    if (req.body[field] != null) {
      res.userDetails[field] = req.body[field];
    }
  });

  try {
    const updatedUserDetails = await res.userDetails.save();
    res.json(updatedUserDetails);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteUserDetails = async (req, res) => {
  try {
    await res.userDetails.deleteOne();
    res.json({ message: "User details deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Middleware
const getUserDetail = async (req, res, next) => {
  let userDetails;
  try {
    userDetails = await UserDetails.findById(req.params.id);
    if (userDetails == null) {
      return res.status(404).json({ message: "Cannot find user details" });
    }
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }

  res.userDetails = userDetails;
  next();
};

module.exports = {
  getUserDetail,
  getAllUserDetails,
  getUserDetailsById,
  createUserDetails,
  updateUserDetails,
  deleteUserDetails,
};
