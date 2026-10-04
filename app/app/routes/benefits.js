const {
    BenefitsDAO
} = require("../data/benefits-dao");
const {
    environmentalScripts
} = require("../../config/config");
const { UserDAO } = require("../data/user-dao");

function BenefitsHandler(db) {
    "use strict";

    const benefitsDAO = new BenefitsDAO(db);

    this.displayBenefits = (req, res, next) => {
        if (!req.session.userId) {
            return res.redirect("/login");
        }
        UserDAO.getUserById(req.session.userId, (err, user) => {
            if (err) return next(err);
            if (!user || !user.isAdmin) {
                return res.status(403).render("403");
            }
            benefitsDAO.getAllNonAdminUsers((error, users) => {
                if (error) return next(error);
                return res.render("benefits", { users, user: { isAdmin:true } });
            });
        });
    };

    this.updateBenefits = (req, res, next) => {
        if (!req.session.userId) {
            return res.redirect("/login");
        }
        userDAO.getUserById(req.session.userId, (err, user) => {
            if (err) return next(err);
            if (!user || !user.isAdmin) {
                return res.status(403).render("403");
            }

            benefitsDAO.updateBenefits(
                req.body.userId,
                req.body.benefitStartDate,
                (error) => {
                    if (error) return next(error);
                    return res.redirect("/benefits");
                }
            );
        });
    };
}

module.exports = BenefitsHandler;
