/*
filedrag.js - HTML5 File Drag & Drop demonstration
Featured on SitePoint.com
Developed by Craig Buckler (@craigbuckler) of OptimalWorks.net
*/
(function() {

	// getElementById
	function $id(id) {
		return document.getElementById(id);
	}


	// output information
	function Output(msg) {
		var m = $id("messages");
		m.innerHTML = msg + m.innerHTML;
	}


	// file drag hover
	function FileDragHover(e) {
		e.stopPropagation();
		e.preventDefault();
		e.target.className = (e.type == "dragover" ? "hover" : "");
	}


	// file selection
	function FileSelectHandler(e) {

		// cancel event and hover styling
		FileDragHover(e);

		// fetch FileList object
		var files = e.target.files || e.dataTransfer.files;

		// process all File objects
		for (var i = 0, f; f = files[i]; i++) {
			UploadFile(f);
		}

	}


	// upload JPEG files
	function UploadFile(file) {
		$id('warningmsg').style.display = "none";

		var xhr = new XMLHttpRequest();
		
		// create progress bar
		var o = $id("filedrag");
		// var progress = o.appendChild(document.createElement("p"));
		// progress.appendChild(document.createTextNode("upload " + file.name));


		// progress bar
		xhr.upload.addEventListener("progress", function(e) {
			var pc = parseInt(100 - (e.loaded / e.total * 100));
			o.style.backgroundPosition = pc + "% 0";
		}, false);

		// file received/failed
		xhr.onreadystatechange = function(e) {
			if (xhr.readyState == 4) {
				$id("filedrag").innerHTML = file.name;
				$id("input_filename").value = file.name;
				o.className = (xhr.status == 200 ? "success" : "failure");
				if (xhr.status == 200) {
					$id("solveForm").style.display = "block";

					var reader = new FileReader();
					reader.onload = function(progressEvent){
						var myrow = '<tr>\
										<td><div id=\"{{NAME}}\">{{NAME}}</div></td>\
										<td>\
											<div class=\"onoffswitch\">\
												<input type=\"checkbox\" name=\"var_{{NAME}}\" class=\"onoffswitch-checkbox\" id=\"var_{{NAME}}\" checked>\
												<label class=\"onoffswitch-label\" for=\"var_{{NAME}}\">\
												<div class=\"onoffswitch-inner\">\
													<span class=\"onoffswitch-active\"><span class=\"onoffswitch-switch\">YES</span></span>\
													<span class=\"onoffswitch-inactive\"><span class=\"onoffswitch-switch\">NO</span></span>\
												</div>\
												</label>\
											</div>\
										</td>\
									</tr>';
					    var lines = this.result.split('\n');
						var cols = lines[0].split(",")
						var s = "";
						for (var c in cols) {
							s += myrow.replace(/{{NAME}}/g, cols[c].replace(/^\s+|\s+$/g, '').replace("\"", "\\\"").replace("\'", "\\\'")) + "\n";
						}
						$id("RowVariables").innerHTML = s;

					  };
					reader.readAsText(file);
				} else {
					$id("solveForm").style.display = "none";									
				}
			}
		};

		// start upload
		if (file.type == "text/csv") {
			xhr.open("POST", $id("upload").action, true);
			xhr.setRequestHeader("X_FILENAME", file.name);
			xhr.send(file);
		} else {
			alert("You must upload a .csv file.")
		}

	}


	// initialize
	function Init() {

		var fileselect = $id("fileselect"),
			filedrag = $id("filedrag"),
			submitbutton = $id("submitbutton");

		// file select
		fileselect.addEventListener("change", FileSelectHandler, false);

		// is XHR2 available?
		var xhr = new XMLHttpRequest();
		if (xhr.upload) {

			// file drop
			filedrag.addEventListener("dragover", FileDragHover, false);
			filedrag.addEventListener("dragleave", FileDragHover, false);
			filedrag.addEventListener("drop", FileSelectHandler, false);
			filedrag.style.display = "block";

			// remove submit button
			submitbutton.style.display = "none";
		}

	}

	// call initialization file
	if (window.File && window.FileList && window.FileReader) {
		Init();
	}


})();