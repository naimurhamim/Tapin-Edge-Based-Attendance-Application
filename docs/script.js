/* ============================================================
   TapIn — GSAP Scroll Animations + Pinned Showcase
   script.js
   ============================================================ */

gsap.registerPlugin(ScrollTrigger);

/* ============================================================
   SHOWCASE STEPS DATA
   Each step = one app screen + sticky notes for left and right
   ============================================================ */
const STEPS = [
  {
    label: "Authentication Flow",
    titleHTML: "Login <span>Screen</span>",
    image: "assets/screenshots/login-empty.jpg",
    leftNotes: [
      { color: "yellow", rot: -2.5, html: "Email + password<br>auth via Supabase.<br>Role auto-detected<br>on login <i data-lucide=\"key\" class=\"inline-icon\"></i>" },
      { color: "orange", rot: 1.8,  html: "<i data-lucide=\"moon\" class=\"inline-icon\"></i> Dark Mode toggle<br>persisted via<br><strong>shared_preferences</strong>" }
    ],
    rightNotes: [
      { color: "blue", rot: -1.4, html: "Admin accounts<br>pre-seeded in DB.<br>No self-registration<br>for admins <i data-lucide=\"lock\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Authentication Flow",
    titleHTML: "Create <span>Account</span>",
    image: "assets/screenshots/register.jpg",
    leftNotes: [
      { color: "pink", rot: 2.0, html: "<strong>Intelligent Routing</strong><br>Last 3 digits of<br>University ID decides<br>your lab group <i data-lucide=\"clipboard-list\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "green",  rot: -1.2, html: "≤ 025 → <strong>Lab G1</strong><br>&gt; 025 → <strong>Lab G2</strong><br>Auto-assigned ✓" },
      { color: "yellow", rot:  2.4, html: "Dept (IRE) &amp; Session<br>(2021-22) auto-filled<br>from University ID" }
    ]
  },
  {
    label: "Student View",
    titleHTML: "Home <span>Dashboard</span>",
    image: "assets/screenshots/student-dashboard.jpg",
    leftNotes: [
      { color: "yellow", rot: -2.8, html: "Overall attendance %<br>Circular indicator —<br>turns <i data-lucide=\"alert-triangle\" class=\"inline-icon\" style=\"color:red\"></i> below<br><strong>90% threshold!</strong>" },
      { color: "pink",   rot:  2.0, html: "<i data-lucide=\"circle\" fill=\"currentColor\" style=\"color:#2563EB\" class=\"inline-icon\"></i> Blue = Theory<br><i data-lucide=\"circle\" fill=\"currentColor\" style=\"color:#06B6D4\" class=\"inline-icon\"></i> Cyan = Lab" }
    ],
    rightNotes: [
      { color: "blue",  rot: -1.4, html: "<strong>Context-Aware Feed</strong><br>Today's classes only,<br>filtered by your<br>Lab Group (G1/G2) <i data-lucide=\"check\" class=\"inline-icon\"></i>" },
      { color: "green", rot:  2.4, html: "<i data-lucide=\"calendar\" class=\"inline-icon\"></i> Sorted by time.<br>Bottom nav for<br>quick section access!" }
    ]
  },
  {
    label: "Attendance Tracking",
    titleHTML: "Per-Subject <span>Attendance</span>",
    image: "assets/screenshots/student-attendance.jpg",
    leftNotes: [
      { color: "green", rot: -2.5, html: "<strong>The 90% Rule</strong> <i data-lucide=\"bar-chart\" class=\"inline-icon\"></i><br>Minimum 90% per<br>subject = full<br><strong>30/30 marks!</strong>" }
    ],
    rightNotes: [
      { color: "yellow", rot:  1.8, html: "Per-subject view:<br>Present / Absent /<br>Total counts<br>at a glance <i data-lucide=\"eye\" class=\"inline-icon\"></i>" },
      { color: "orange", rot: -1.5, html: "Color-coded bars<br>for instant visual<br>feedback <i data-lucide=\"trending-up\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Attendance Tracking",
    titleHTML: "Attendance <span>History</span>",
    image: "assets/screenshots/student-history.jpg",
    leftNotes: [
      { color: "blue", rot: -2.0, html: "<strong>Chronological Log</strong><br>Immutable entries<br>with exact Entry &amp;<br>Exit times (hh:mm a) <i data-lucide=\"clock\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "purple", rot:  1.5, html: "<strong>PRESENT</strong> badge<br>in green = verified<br>attendance <i data-lucide=\"check-circle-2\" class=\"inline-icon\"></i>" },
      { color: "pink",   rot: -1.8, html: "Date stored as<br>YYYY-MM-DD format<br>in Supabase DB <i data-lucide=\"calendar\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Leave Management",
    titleHTML: "Leave <span>Application</span>",
    image: "assets/screenshots/student-leave.jpg",
    leftNotes: [
      { color: "yellow", rot: -2.5, html: "Select subject,<br>date &amp; reason.<br>Submit → Status:<br><strong>Pending</strong> <i data-lucide=\"file-edit\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "orange", rot:  1.8, html: "Leave types:<br>• Medical<br>• General<br>• University Event" },
      { color: "blue",   rot: -1.4, html: "Approved absences<br>count as<br><strong>PRESENT</strong> for<br>90% calculation! <i data-lucide=\"target\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Leave Management — Admin",
    titleHTML: "Pending <span>Requests</span>",
    image: "assets/screenshots/admin-leave-pending.jpg",
    leftNotes: [
      { color: "pink", rot: -2.0, html: "Admin sees ALL<br>pending leave<br>requests from<br>students <i data-lucide=\"clipboard-list\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "green",  rot:  1.5, html: "Approve → DB updates<br>to <strong>'Condoned'</strong><br>status instantly <i data-lucide=\"check-circle-2\" class=\"inline-icon\"></i>" },
      { color: "yellow", rot: -1.8, html: "Student name, ID<br>&amp; reason visible<br>for each request <i data-lucide=\"eye\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Leave Management — Admin",
    titleHTML: "Approved <span>Leaves</span>",
    image: "assets/screenshots/admin-leave-approved.jpg",
    leftNotes: [
      { color: "green", rot: -2.5, html: "<strong>APPROVED</strong> badge<br>shown in green.<br>Student's record<br>updated instantly <i data-lucide=\"check-circle-2\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "blue", rot: 1.8, html: "Condoned absences<br>automatically count<br>as PRESENT in the<br>90% calculation <i data-lucide=\"bar-chart\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Admin Panel",
    titleHTML: "Admin <span>Dashboard</span>",
    image: "assets/screenshots/admin-dashboard.jpg",
    leftNotes: [
      { color: "yellow", rot: -2.8, html: "<i data-lucide=\"users\" class=\"inline-icon\"></i> <strong>Total Students</strong><br>Filtered by<br>Dept (IRE),<br>Sec (2021-22)" },
      { color: "orange", rot:  2.0, html: "<i data-lucide=\"hourglass\" class=\"inline-icon\"></i> <strong>Pending Leaves</strong><br>Live queue from<br>'leave_applications'" }
    ],
    rightNotes: [
      { color: "blue",  rot: -1.4, html: "<i data-lucide=\"check-circle-2\" class=\"inline-icon\"></i> <strong>Today Present</strong><br>Real-time JOIN<br>of 'users' &amp;<br>'attendance_logs'" },
      { color: "green", rot:  2.4, html: "<i data-lucide=\"book-open\" class=\"inline-icon\"></i> <strong>Today's Classes</strong><br>'class_schedules'<br>where is_active=true" }
    ]
  },
  {
    label: "Critical Admin Operations",
    titleHTML: "Student <span>Management</span>",
    image: "assets/screenshots/admin-students.jpg",
    leftNotes: [
      { color: "pink", rot: -2.0, html: "<i data-lucide=\"radio\" class=\"inline-icon\"></i> <strong>RFID UID Link</strong><br>Admin MUST assign<br>physical RFID UID<br>to each student!" }
    ],
    rightNotes: [
      { color: "purple", rot:  1.5, html: "Without this link,<br>Edge Functions<br><strong>cannot</strong> process<br>RFID taps <i data-lucide=\"x-circle\" class=\"inline-icon\"></i>" },
      { color: "yellow", rot: -1.8, html: "e.g. RFID UID:<br><strong>EBACC836</strong><br>linked to student<br>profile <i data-lucide=\"link\" class=\"inline-icon\"></i>" }
    ]
  },
  {
    label: "Critical Admin Operations",
    titleHTML: "Class <span>Schedules</span>",
    image: "assets/screenshots/admin-schedule.jpg",
    leftNotes: [
      { color: "blue", rot: -2.5, html: "Admin manages<br>all class timetables.<br>Sets active/inactive<br>status <i data-lucide=\"calendar\" class=\"inline-icon\"></i>" }
    ],
    rightNotes: [
      { color: "green",  rot:  1.8, html: "Sat → Thu<br>Bangladesh Academic<br>Week logic<br>built-in <i data-lucide=\"check\" class=\"inline-icon\"></i>" },
      { color: "orange", rot: -1.5, html: "is_active=true →<br>shown in Today's<br>Classes feed<br>for students <i data-lucide=\"smartphone\" class=\"inline-icon\"></i>" }
    ]
  }
];

/* ============================================================
   INIT — DOM REFERENCES
   ============================================================ */
const scImg     = document.getElementById('sc-img');
const scLeft    = document.getElementById('sc-left');
const scRight   = document.getElementById('sc-right');
const scLabel   = document.getElementById('sc-label');
const scTitle   = document.getElementById('sc-title');
const scCounter = document.getElementById('sc-counter');
const scDots    = document.getElementById('sc-dots');

let currentStepIndex = -1;

/* ============================================================
   BUILD PROGRESS DOTS
   ============================================================ */
STEPS.forEach((_, i) => {
  const dot = document.createElement('div');
  dot.className = 'sc-dot';
  dot.dataset.step = i;
  dot.addEventListener('click', () => scrollToStep(i));
  scDots.appendChild(dot);
});

/* ============================================================
   RENDER NOTES — creates note elements inside columns
   ============================================================ */
function renderNotes(step) {
  scLeft.innerHTML  = step.leftNotes.map(n =>
    `<div class="sc-sticky ${n.color}" data-rot="${n.rot}">${n.html}</div>`
  ).join('');
  scRight.innerHTML = step.rightNotes.map(n =>
    `<div class="sc-sticky ${n.color}" data-rot="${n.rot}">${n.html}</div>`
  ).join('');
}

/* ============================================================
   TRANSITION TO A STEP
   direction: 1 = scroll down (notes exit up, enter from below)
              -1 = scroll up (notes exit down, enter from above)
   ============================================================ */
function transitionToStep(index, direction) {
  if (index === currentStepIndex) return;
  const step = STEPS[index];
  const outY = direction >= 0 ? -90 : 90;
  const inY  = direction >= 0 ?  90 : -90;

  const existingNotes = document.querySelectorAll('.sc-sticky');

  const doTransition = () => {
    /* -- Render new notes (hidden off-screen) -- */
    renderNotes(step);
    if (typeof lucide !== 'undefined') lucide.createIcons();
    const newNotes = document.querySelectorAll('.sc-sticky');

    /* -- Apply initial rotation to each note via GSAP -- */
    newNotes.forEach(el => {
      const rot = parseFloat(el.dataset.rot) || 0;
      gsap.set(el, { y: inY, opacity: 0, rotation: rot });
    });

    /* -- Animate notes in, then start float loop -- */
    gsap.to(newNotes, {
      y: 0,
      opacity: 1,
      duration: 0.55,
      stagger: 0.08,
      ease: 'back.out(1.4)',
      onComplete: () => {
        newNotes.forEach((el, i) => {
          gsap.to(el, {
            y: i % 2 === 0 ? '-=6' : '+=6',
            duration: 2.0 + (i % 3) * 0.5,
            repeat: -1,
            yoyo: true,
            ease: 'sine.inOut',
            delay: i * 0.2,
          });
        });
      }
    });

    /* -- Phone Animation Logic -- */
    const phone = document.getElementById('sc-phone');
    const phoneWrap = document.getElementById('sc-phone-wrap');
    const rightCol = document.getElementById('sc-right');
    // Calculate distance between center and right column
    const dx = rightCol.offsetLeft - phoneWrap.offsetLeft;

    const tl = gsap.timeline();

    if (currentStepIndex === 1 && index === 2) {
      // Step 2 -> 3: Slide Right
      tl.to(phoneWrap, { x: dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol, { x: -dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });
    } else if (currentStepIndex === 2 && index === 1) {
      // Step 3 -> 2: Slide Back
      tl.to(phoneWrap, { x: 0, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol, { x: 0, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });
    } else if (currentStepIndex === 3 && index === 4) {
      // Step 4 -> 5: Phone slides LEFT, left notes slide RIGHT
      const ldx = rightCol.offsetLeft - phoneWrap.offsetLeft; // symmetric distance
      tl.to(phoneWrap, { x: -ldx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(scLeft,    { x:  ldx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol,  { x:    0, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });

    } else if (currentStepIndex === 4 && index === 3) {
      // Step 5 -> 4: Reverse — phone slides RIGHT, left notes slide back LEFT
      const ldx = rightCol.offsetLeft - phoneWrap.offsetLeft;
      tl.to(phoneWrap, { x:  ldx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(scLeft,    { x:    0, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol,  { x: -ldx, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });

    } else if (currentStepIndex === 6 && index === 7) {
      // Step 7 -> 8: Phone slides LEFT to RIGHT, right notes slide RIGHT to LEFT (center)
      const dx = rightCol.offsetLeft - phoneWrap.offsetLeft;
      tl.to(phoneWrap, { x:   dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol,  { x:  -dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(scLeft,   { x:    0, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });

    } else if (currentStepIndex === 7 && index === 6) {
      // Step 8 -> 7: Reverse — phone slides RIGHT to LEFT, right notes slide back
      const dx = rightCol.offsetLeft - phoneWrap.offsetLeft;
      tl.to(phoneWrap, { x:  -dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(rightCol,  { x:    0, duration: 0.6, ease: 'power2.inOut' }, 0);
      tl.to(scLeft,   { x:   dx, duration: 0.6, ease: 'power2.inOut' }, 0);
      gsap.to(scImg, {
        opacity: 0, duration: 0.2, delay: 0.1, onComplete: () => {
          scImg.src = step.image;
          gsap.to(scImg, { opacity: 1, duration: 0.3 });
        }
      });

    } else {
      // Default 3D Flip
      tl.to(phone, {
        rotationY: direction >= 0 ? 90 : -90,
        scale: 0.9,
        duration: 0.25,
        ease: 'power1.in',
        onComplete: () => {
          scImg.src = step.image;
          gsap.set(phone, { rotationY: direction >= 0 ? -90 : 90 });
        }
      })
      .to(phone, {
        rotationY: 0,
        scale: 1,
        duration: 0.35,
        ease: 'power1.out'
      });
    }

    /* -- Update header text (slide up/down) -- */
    gsap.to([scLabel, scTitle], {
      opacity: 0,
      y: outY * 0.3,
      duration: 0.22,
      ease: 'power2.in',
      onComplete: () => {
        scLabel.textContent = step.label;
        scTitle.innerHTML   = step.titleHTML;
        gsap.fromTo([scLabel, scTitle],
          { opacity: 0, y: inY * 0.3 },
          { opacity: 1, y: 0, duration: 0.3, ease: 'power2.out' }
        );
      }
    });

    /* -- Update counter -- */
    scCounter.textContent = `${String(index + 1).padStart(2, '0')} / ${STEPS.length}`;

    /* -- Update dots -- */
    document.querySelectorAll('.sc-dot').forEach((dot, i) => {
      dot.classList.toggle('active', i === index);
    });

    currentStepIndex = index;
    updateNavButtons();
  };

  /* -- Animate current notes out first -- */
  if (existingNotes.length > 0) {
    gsap.to(existingNotes, {
      y: outY,
      opacity: 0,
      duration: 0.32,
      stagger: 0.05,
      ease: 'power2.in',
      onComplete: doTransition
    });
  } else {
    doTransition();
  }
}

/* ============================================================
   SCROLL TO STEP (dot click)
   ============================================================ */
function scrollToStep(index) {
  const section = document.getElementById('showcase-section');
  const sectionTop = section.getBoundingClientRect().top + window.scrollY;
  const stepOffset = (index / STEPS.length) * (STEPS.length * window.innerHeight);
  window.scrollTo({ top: sectionTop + stepOffset, behavior: 'smooth' });
}

/* ============================================================
   PREV / NEXT ARROW BUTTONS
   ============================================================ */
const scPrev = document.getElementById('sc-prev');
const scNext = document.getElementById('sc-next');

function updateNavButtons() {
  if (!scPrev || !scNext) return;
  scPrev.disabled = currentStepIndex <= 0;
  scNext.disabled = currentStepIndex >= STEPS.length - 1;
}

scPrev.addEventListener('click', () => {
  if (currentStepIndex > 0) scrollToStep(currentStepIndex - 1);
});

scNext.addEventListener('click', () => {
  if (currentStepIndex < STEPS.length - 1) scrollToStep(currentStepIndex + 1);
});


/* ============================================================
   GSAP PINNED SHOWCASE
   ============================================================ */
ScrollTrigger.create({
  trigger: '#showcase-section',
  start: 'top top',
  end: () => `+=${STEPS.length * window.innerHeight}`,
  pin: '#showcase-pin',
  pinSpacing: true,
  onUpdate: (self) => {
    /* Determine current step from scroll progress */
    const rawIndex = Math.floor(self.progress * STEPS.length);
    const index = Math.min(rawIndex, STEPS.length - 1);
    transitionToStep(index, self.direction);
  },
  onEnter: () => {
    /* Initialize first step on entering the section */
    if (currentStepIndex === -1) transitionToStep(0, 1);
  }
});

/* Fix for overlapping: recalculate scroll positions after images load */
window.addEventListener('load', () => {
  ScrollTrigger.refresh();
});

/* ============================================================
   REGULAR SECTION ANIMATIONS (Slides 1–4 and 11)
   ============================================================ */
function animateSlide(id) {
  gsap.timeline({
    scrollTrigger: {
      trigger: `#${id}`,
      start: 'top 75%',
      toggleActions: 'play none none none',
    }
  })
  .to(`#${id} .gsap-fade`,   { opacity: 1, y: 0, duration: 0.6, ease: 'power3.out', stagger: 0.1 })
  .to(`#${id} .gsap-sticky`, { opacity: 1, y: 0, duration: 0.5, ease: 'back.out(1.4)', stagger: 0.1 }, '<0.1')
  .to(`#${id} .gsap-scale`,  { opacity: 1, scale: 1, duration: 0.5, ease: 'power2.out', stagger: 0.1 }, '<0.1');
}

['slide-1', 'slide-2', 'slide-3', 'slide-4', 'slide-11', 'slide-thankyou'].forEach(animateSlide);

/* ============================================================
   SUBTLE FLOAT ANIMATION on non-showcase sticky notes
   (showcase notes are managed by transition logic)
   ============================================================ */
document.querySelectorAll('.s2-sticky, .s3-notes .sticky, .s4-notes .sticky, .s11-grid .sticky').forEach((el, i) => {
  gsap.to(el, {
    y: i % 2 === 0 ? '-=5' : '+=5',
    duration: 2.0 + (i % 3) * 0.5,
    repeat: -1,
    yoyo: true,
    ease: 'sine.inOut',
    delay: i * 0.18,
  });
});

/* Initialize Lucide icons on page load */
if (typeof lucide !== 'undefined') {
  lucide.createIcons();
}
