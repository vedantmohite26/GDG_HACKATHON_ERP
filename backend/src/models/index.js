const { Sequelize } = require('sequelize');

// Initialize Sequelize
const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Import models
const Certificate = require('./Certificate')(sequelize);
const User = require('./User')(sequelize);

// Define associations if needed
// Certificate.belongsTo(User, { foreignKey: 'student_uid' });

const db = {
  sequelize,
  Sequelize,
  Certificate,
  User
};

module.exports = db;
