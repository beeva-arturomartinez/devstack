# Load database dumps for the largest databases to save time
./load-db.sh edxapp
./load-db.sh edxapp_csmh

# Bring the rest of the services online
docker-compose up -d lms

# Run edxapp migrations first since they are needed for the service users and OAuth clients
docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && paver install_prereqs'
docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && NO_PREREQ_INSTALL=1 paver update_db --settings devstack_docker'

# Create a superuser for edxapp
docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && python /edx/app/edxapp/edx-platform/manage.py lms --settings=devstack_docker manage_user edx edx@example.com --superuser --staff'
docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && echo "from django.contrib.auth import get_user_model; User = get_user_model(); user = User.objects.get(username=\"edx\"); user.set_password(\"edx\"); user.save()" | python /edx/app/edxapp/edx-platform/manage.py lms shell  --settings=devstack_docker'

# Enable the LMS-E-Commerce integration
docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && python /edx/app/edxapp/edx-platform/manage.py lms --settings=devstack_docker configure_commerce'

# Create demo course and users
docker exec -t edx.devstack.lms  bash -c '/edx/app/edx_ansible/venvs/edx_ansible/bin/ansible-playbook /edx/app/edx_ansible/edx_ansible/playbooks/edx-east/demo.yml -v -c local -i "127.0.0.1," --extra-vars="COMMON_EDXAPP_SETTINGS=devstack_docker"'

# @TODO Why is this necessary? Right now installing prereqs crashes the server
docker restart edx.devstack.lms

docker exec -t edx.devstack.lms  bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform && paver update_assets --settings devstack_docker'
