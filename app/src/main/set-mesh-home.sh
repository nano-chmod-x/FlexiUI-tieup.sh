# One way to set the MESH_HOME path is here via this variable.  Simply uncomment it and set a valid path like
# /mesh/home.  You can of course set it outside in the command terminal; that will also work.
#
if [ -z "$MESH_HOME" ]; then
    MESH_HOME=
fi

# When upgrading from the packaged distribution MESH_HOME may not be set. Output a message for the user recommending 
# that they update their environment
if [ -z "$MESH_HOME" ]; then
      echo "Bitbucket Mesh doesn't know where to store its data. Configure the MESH_HOME"
      echo "environment variable with the directory where Bitbucket Mesh should store its data."
      echo "Ensure the path to MESH_HOME does not contain spaces. MESH_HOME may"
      echo "be configured in set-mesh-home.sh, if preferred, rather than exporting it"
      echo "as an environment variable"
      return 1
fi

echo $MESH_HOME | grep -q " "
if [ $? -eq 0 ]; then
    echo "MESH_HOME '$MESH_HOME' contains spaces."
    echo "Using a directory with spaces is likely to cause unexpected behaviour and is not"
    echo "supported. Set MESH_HOME to a directory which does not contain spaces"
    return 1
fi

export MESH_HOME