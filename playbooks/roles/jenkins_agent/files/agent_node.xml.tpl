<?xml version="1.1" encoding="UTF-8"?>
<slave>
  <name>@@NAME@@</name>
  <description>@@DESCRIPTION@@</description>
  <remoteFS>@@REMOTE_FS@@</remoteFS>
  <numExecutors>1</numExecutors>
  <mode>EXCLUSIVE</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.slaves.JNLPLauncher">
    <workDirSettings>
      <disabled>false</disabled>
      <internalDir>remoting</internalDir>
      <failIfWorkDirIsMissing>false</failIfWorkDirIsMissing>
    </workDirSettings>
    <webSocket>false</webSocket>
  </launcher>
  <label>@@LABELS@@</label>
  <nodeProperties/>
</slave>
