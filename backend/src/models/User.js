const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const User = sequelize.define('User', {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    firebase_uid: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      index: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true
      }
    },
    role: {
      type: DataTypes.ENUM('student', 'faculty', 'committee', 'admin'),
      allowNull: false,
      defaultValue: 'student'
    },
    student_uid: {
      type: DataTypes.STRING,
      allowNull: true,
      index: true,
      comment: 'Student ID if role is student'
    },
    last_login: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    tableName: 'users',
    timestamps: true,
    indexes: [
      { fields: ['firebase_uid'], unique: true },
      { fields: ['email'], unique: true },
      { fields: ['student_uid'] }
    ]
  });

  return User;
};
