  $().ready(function() {
    // Read cookie
    var preferredLogin = $.cookie('preferredLogin');

    // Set 'remember' checkbox according to preferredLogin cookie
    if( preferredLogin == 'otp') {
      $('#rememberotp').attr('checked', true);
    }

    if( preferredLogin == 'software') {
      $('#remembersoftware').attr('checked', true);
    }

    // Set 'remember' checkbox according to preferredLogin cookie
    if( preferredLogin == 'digitalsignatur') {
      $('#rememberdigitalsignatur').attr('checked', true);
    }

    // Set preferredLogin cookie
    $('#rememberotp').click(function(){
      if($('#rememberotp').is(':checked')) {
        $.cookie('preferredLogin', 'otp', { expires: 365, path: '/' });
      } else {
        $.cookie('preferredLogin', '', { expires: 365, path: '/' });
      }
    });

    // Set preferredLogin cookie
    $('#remembersoftware').click(function(){
      if($('#remembersoftware').is(':checked')) {
        $.cookie('preferredLogin', 'software', { expires: 365, path: '/' });
      } else {
        $.cookie('preferredLogin', '', { expires: 365, path: '/' });
      }
    });

    // Set preferredLogin cookie
    $('#rememberdigitalsignatur').click(function(){
      if($('#rememberdigitalsignatur').is(':checked')) {
        $.cookie('preferredLogin', 'digitalsignatur',
          { expires: 365, path: '/' });
      } else {
        $.cookie('preferredLogin', '', { expires: 365, path: '/' });
      }
    });
  });

  function onLogonOk(signature) {
    document.signedForm.signature.value=signature;
    // ok base64 encoded => b2s=
    document.signedForm.result.value="b2s="
    document.signedForm.submit();
  }
  function onLogonCancel(msg) {
    document.signedForm.result.value=msg;
    document.signedForm.submit();
  }
  function onLogonError(msg) {
    document.signedForm.result.value=msg;
    document.signedForm.submit();
  }

  function onSignOk(signature) {
    document.signedForm.signature.value=signature;
    document.signedForm.result.value="b2s="
    document.signedForm.submit();
  }
  function onSignCancel(msg) {
    document.signedForm.result.value=msg;
    document.signedForm.submit();
  }
  function onSignError(msg) {
    document.signedForm.result.value=msg;
    document.signedForm.submit();
  }

  function onNemidMessage(e) {
    var event = e || event;
    var win = document.getElementById("nemid_iframe").contentWindow,
      postMessage = {}, message;
    message = JSON.parse(event.data);

    if (message.command == "SendParameters") {
      var htmlParameters = document.getElementById("nemid_parameters").
        innerHTML;
      postMessage.command = "Parameters";
      postMessage.content = htmlParameters;
      win.postMessage(JSON.stringify(postMessage), "https://applet.danid.dk");
    }
    if (message.command == "changeResponseAndSubmit") {
      document.NemIDPostBack.response.value = message.content;
      document.NemIDPostBack.submit();
    }
  }

  if(window.addEventListener) {
    window.addEventListener("message", onNemidMessage);
  } else if (window.attachEvent) {
    window.attachEvent("onmessage", onNemidMessage);
  }
