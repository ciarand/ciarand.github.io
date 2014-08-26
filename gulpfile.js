var gulp = require("gulp"),
    concat = require("gulp-concat"),
    minifycss = require("gulp-minify-css"),
    css;

css = function (name) {
    return "./css/" + name + ".css";
};

gulp.task("css", function () {
    gulp.src([css("poole"), css("lanyon"), css("syntax")])
        .pipe(concat("style.css"))
        .pipe(minifycss({}))
        .pipe(gulp.dest("./css/"));
});

gulp.task("default", ["css"]);
