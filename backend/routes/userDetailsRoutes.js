const express = require("express");
const {
  getUserDetail,
  getAllUserDetails,
  getUserDetailsById,
  createUserDetails,
  updateUserDetails,
  deleteUserDetails,
} = require( "../controllers/userDetailsController.js");

const router = express.Router();

router.get("/", getAllUserDetails);
router.get("/:id", getUserDetail, getUserDetailsById);
router.post("/", createUserDetails);
router.patch("/:id", getUserDetail, updateUserDetails);
router.delete("/:id", getUserDetail, deleteUserDetails);

module.exports = router;
