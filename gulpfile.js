var gulp      = require("gulp"),
    concat    = require("gulp-concat"),
    rename    = require("gulp-rename"),
    glob      = require("glob"),
    uncss     = require("gulp-uncss"),
    minifycss = require("gulp-minify-css"),
    css       = function (name) {
        return "./css/" + name + ".css";
    },
    cssfiles  = [css("poole"), css("lanyon"), css("syntax")];

gulp.task("minifycss", function () {
    glob("./_site/**/*.html", function (err, htmlfiles) {
        if (err) {
            throw err;
        }

        gulp.src(cssfiles)
            .pipe(concat("style.css"))
            .pipe(uncss({
                html: htmlfiles
            }))
            .pipe(minifycss({}))
            .pipe(gulp.dest("./css/"));
    });
});

gulp.task("default", ["minifycss"]);
